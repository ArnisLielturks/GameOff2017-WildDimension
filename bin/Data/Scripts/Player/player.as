namespace Player {
    const int CTRL_FORWARD = 1;
    const int CTRL_BACK = 2;
    const int CTRL_LEFT = 4;
    const int CTRL_RIGHT = 8;
    const int CTRL_JUMP = 16;
    const int CTRL_SPRINT = 32;
    const int CTRL_DUCK = 64;

    const float NOCLIP_SPEED = 1.0f;

    Node@ playerNode;
    Controls playerControls;
    RigidBody@ playerBody;
    const float PLAYER_BRAKE_FORCE = 1.0f;
    const float PLAYER_MOVE_FORCE = 6.0f;
    SoundSource@ walkSoundSource;
    CollisionShape@ shape;
    String destination;
    bool onGround;
    bool noclip = false;
    float lastHurt = 0.0f;
    bool underWater = false;

    Node@ CreatePlayer()
    {
        Vector3 position = scene_.GetChild("PlayerStartPosition", true).worldPosition;
        position.x += -50.0f;
        position.z += -50.0f;
        position.y = NetworkHandler::terrain.GetHeight(position);
        playerNode = scene_.CreateChild("PlayerNode");
        playerNode.AddTag("Player");
        playerNode.position = position;
        playerNode.temporary = true;
        playerNode.AddTag("Player");
        // Create rigidbody, and set non-zero mass so that the body becomes dynamic
        playerBody = playerNode.CreateComponent("RigidBody");
        playerBody.collisionLayer = COLLISION_PLAYER_LEVEL;
        playerBody.collisionMask = COLLISION_TERRAIN_LEVEL | COLLISION_PACMAN_LEVEL | COLLISION_SNAKE_BODY_LEVEL | COLLISION_SNAKE_HEAD_LEVEL | COLLISION_PICKABLE_LEVEL | COLLISION_FOOD_LEVEL | COLLISION_TREE_LEVEL | COLLISION_STATIC_OBJECTS;
        playerBody.mass = 80.0f;

        // Set zero angular factor so that physics doesn't turn the character on its own.
        // Instead we will control the character yaw manually
        playerBody.angularFactor = Vector3::ZERO;

        // Set the rigidbody to signal collision also when in rest, so that we get ground collisions properly
        //playerBody.collisionEventMode = COLLISION_ALWAYS;

        // Set a capsule shape for collision
        shape = playerNode.CreateComponent("CollisionShape");
        shape.SetCapsule(0.7f, 1.8f, Vector3(0.0f, 0.5f, 0.0f));

        // Get the sound resource
        Sound@ sound = cache.GetResource("Sound", GameSounds::WALK);

        if (sound !is null) {
            sound.looped = true;
            // Create a SoundSource component for playing the sound. The SoundSource component plays
            // non-positional audio, so its 3D position in the scene does not matter. For positional sounds the
            // SoundSource3D component would be used instead
            walkSoundSource = playerNode.CreateComponent("SoundSource");
            //soundSource.autoRemoveMode = REMOVE_COMPONENT;
            walkSoundSource.Play(sound);
            // In case we also play music, set the sound volume below maximum so that we don't clip the output
            walkSoundSource.gain = 0.0f;
            log.Debug("Player walk sound created");
        }

        SubscribeToEvent(playerNode, "NodeCollision", "Player::HandleNodeCollision");
        Subscribe();
        RegisterConsoleCommands();
        
        position.y = 50;
        position.x = 0;
        position.z = 0;
        //position, minSpawnRadius, maxSpawnRadius, maxUnitRadius, maxUnits, spawnTime, type
        Node@ cloudSpawner = Spawn::Create(position, 0.0f, 50.0f, 100.0, 30, 1.0f, Spawn::SPAWN_UNIT_TETRIS);
        playerNode.AddChild(cloudSpawner);
        return playerNode;
    }

    void Subscribe()
    {
        SubscribeToEvent("NoclipToggle", "Player::HandleNoclip");
        SubscribeToEvent("PlayerHit", "Player::HandlePlayerHit");
    }

    void RegisterConsoleCommands()
    {
        VariantMap data;
        data["CONSOLE_COMMAND_NAME"] = "noclip";
        data["CONSOLE_COMMAND_EVENT"] = "NoclipToggle";
        SendEvent("ConsoleCommandAdd", data);
    }

    void HandlePlayerHit(StringHash eventType, VariantMap& eventData)
    {
        if (lastHurt < 1.0f) {
            return;
        }
        VariantMap data;
        data["Message"] = "You're hurt!";
        data["Type"] = Notifications::NOTIFICATION_TYPE_BAD;
        SendEvent("AddNotification", data);
        GameSounds::Play(GameSounds::PLAYER_HURT);
        AddBlur();
        playerBody.ApplyImpulse(Vector3::UP * 8 * playerBody.mass);
        lastHurt = 0.0f;
    }

    void HandleNoclip(StringHash eventType, VariantMap& eventData)
    {
        noclip = !noclip;
        log.Warning("Noclip " + noclip);
        if (noclip) {
            playerBody.enabled = false;
            shape.enabled = false;
        } else {
            playerBody.enabled = true;
            shape.enabled = true;
        }
    }

    void HandlePhysicsPreStep(StringHash eventType, VariantMap& eventData)
    {
        if (playerNode is null) {
            return;
        }

        Controls oldControls = playerControls;
        float timeStep = eventData["TimeStep"].GetFloat();
        lastHurt += timeStep;
        if (isMobilePlatform) {
            //playerControls.Set(CTRL_FORWARD, input.keyDown[BUTTON_A]);
        } else {
            if (!ConsoleHandler::console.visible) {
                playerControls.Set(CTRL_FORWARD, input.keyDown[KEY_W]);
                playerControls.Set(CTRL_BACK, input.keyDown[KEY_S]);
                playerControls.Set(CTRL_LEFT, input.keyDown[KEY_A]);
                playerControls.Set(CTRL_RIGHT, input.keyDown[KEY_D]);
                playerControls.Set(CTRL_SPRINT, input.keyDown[KEY_LSHIFT]);
                playerControls.Set(CTRL_DUCK, input.keyDown[KEY_LCTRL]);
                playerControls.Set(CTRL_JUMP, input.keyDown[KEY_SPACE]);
            }
        }

        Vector3 moveDir(0.0f, 0.0f, 0.0f);

        if (playerControls.IsDown(CTRL_FORWARD)) {
            moveDir += Vector3::FORWARD;
            //log.Info("moving forward");
        }
        if (playerControls.IsDown(CTRL_BACK)) {
            moveDir += Vector3::BACK;
            //log.Info("moving backward");
        }
        if (playerControls.IsDown(CTRL_LEFT)) {
            moveDir += Vector3::LEFT;
            //log.Info("moving left");
        }
        if (playerControls.IsDown(CTRL_RIGHT)) {
            moveDir += Vector3::RIGHT;
            //log.Info("moving right");
        }
        if (playerControls.IsDown(CTRL_DUCK)) {
            shape.SetCapsule(0.7f, 1.1f, Vector3(0.0f, 0.5f, 0.0f));
        } else {
            shape.SetCapsule(0.7f, 1.8f, Vector3(0.0f, 0.5f, 0.0f));
        }

        if (walkSoundSource !is null) {
            if (moveDir.lengthSquared == 0) {
                walkSoundSource.gain = 0.0f;
            } else {
                walkSoundSource.gain = 0.3f;
            }
        }

        bool jump = false;
        if (playerControls.IsPressed(CTRL_JUMP, oldControls)) {
            jump = true;
        }

        Quaternion lookAt = Quaternion(pitch, yaw, 0.0f);

        //Ignore Y to allow moving only in X,Z directions
        Quaternion lookAt2 = Quaternion(0.0f, yaw, 0.0f);
        if (noclip) {
            playerNode.rotation = lookAt;
        } else {
            playerNode.rotation = lookAt2;
        }
        Quaternion rot = playerNode.rotation;

        Vector3 position = playerNode.position;

        Vector3 velocity = playerBody.linearVelocity;
        // Velocity on the XZ plane
        Vector3 planeVelocity(velocity.x, 0.1f, velocity.z);

        //position = lookAt * moveDir * timeStep * 30 + position;
        //playerNode.position = position;
         // Normalize move vector so that diagonal strafing is not faster
        if (moveDir.lengthSquared > 0.0f) {
            moveDir.Normalize();
        }
        moveDir *= PLAYER_MOVE_FORCE * playerBody.mass;

        if (playerControls.IsDown(CTRL_SPRINT)) {
            moveDir *= 2;
        }
        if (noclip) {
            moveDir /= playerBody.mass;
            playerNode.Translate(lookAt * moveDir * NOCLIP_SPEED, TS_WORLD);
        } else {
            playerBody.ApplyImpulse(lookAt2 * moveDir);
        }

        Vector3 brakeForce = -planeVelocity * PLAYER_BRAKE_FORCE *  playerBody.mass;
        playerBody.ApplyImpulse(brakeForce);

        if (jump && onGround) {
            playerBody.ApplyImpulse(Vector3::UP * 8 * playerBody.mass);
            GameSounds::Play(GameSounds::JUMP, 0.2);
        }

        if (playerNode.worldPosition.y < 99.5) {
            if (playerNode.worldPosition.y < 99) {
                SetUnderWater(true);
            }
            Vector3 planeVelocity(velocity.x, velocity.y, velocity.z);
            Vector3 brakeForce = -planeVelocity * PLAYER_BRAKE_FORCE *  playerBody.mass * 0.05;
            playerBody.ApplyImpulse(brakeForce);
            playerBody.ApplyImpulse(Vector3::UP * 0.4 * playerBody.mass);
        } else {
            SetUnderWater(false);
        }

        if (playerNode.position.y < NetworkHandler::terrain.GetHeight(playerNode.position)) {
            Vector3 playerPosition = playerNode.position;
            playerPosition.y = NetworkHandler::terrain.GetHeight(playerPosition);
            playerNode.position = playerPosition;
        }

        onGround = false;
    }

    void SetUnderWater(bool value)
    {
        if (underWater != value) {
            if (value) {
                RenderPath@ effectRenderPath = viewport.renderPath.Clone();
                effectRenderPath.SetEnabled("Blur", true);
                viewport.renderPath = effectRenderPath;
            } else {
                RenderPath@ effectRenderPath = viewport.renderPath.Clone();
                effectRenderPath.SetEnabled("Blur", false);
                viewport.renderPath = effectRenderPath;
            }
        }
        underWater = value;
    }
    void HandleKeyDown(StringHash eventType, VariantMap& eventData)
    {
        int key = eventData["Key"].GetInt();
        if (key == KEY_W) {
        }
    }

    void HandleKeyUp(StringHash eventType, VariantMap& eventData)
    {
        int key = eventData["Key"].GetInt();
        if (key == KEY_F1) {
        }
    }

    void HandleNodeCollision(StringHash eventType, VariantMap& eventData)
    {
        VectorBuffer contacts = eventData["Contacts"].GetBuffer();

        while (!contacts.eof)
        {
            Vector3 contactPosition = contacts.ReadVector3();
            Vector3 contactNormal = contacts.ReadVector3();
            float contactDistance = contacts.ReadFloat();
            float contactImpulse = contacts.ReadFloat();

            // If contact is below node center and pointing up, assume it's a ground contact
            if (contactPosition.y < (playerNode.position.y + 1.0f))
            {
                float level = contactNormal.y;
                if (level > 0.75)
                    onGround = true;
            }
        }
    }

    void End()
    {
        playerBody.enabled = false;
        shape.enabled = false;
    }

}