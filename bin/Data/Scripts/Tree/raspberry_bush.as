namespace RaspberryBush {
	class Bush {
		Node@ node;
		float lifetime;
		StaticModel@ model;
		uint stage;
		Array<Node@> berries;
	}
	Array<Bush@> trees;

	Node@ Create(Vector3 position)
	{
		Node@ treeNode = scene_.CreateChild("RaspberryBush");
		position.y = NetworkHandler::terrain.GetHeight(position);
		treeNode.position = position;

		Node@ adjNode = treeNode.CreateChild("AdjNode");
    	adjNode.rotation = Quaternion(-90.0f, Vector3::UP);

	    StaticModel@ object = adjNode.CreateComponent("StaticModel");
        object.model = cache.GetResource("Model", "Models/Models/Raspberry_bush.mdl");
    	treeNode.SetScale(0.8f + Random(0.5f));
        object.castShadows = true;
        object.materials[0] = cache.GetResource("Material", "Materials/TreeGreen.xml");

        // Create rigidbody, and set non-zero mass so that the body becomes dynamic
	    RigidBody@ body = treeNode.CreateComponent("RigidBody");
	    body.collisionLayer = 1;
	    body.mass = 0.0f;

	    // Set zero angular factor so that physics doesn't turn the character on its own.
	    // Instead we will control the character yaw manually
	    body.angularFactor = Vector3::ZERO;

	    // Set the rigidbody to signal collision also when in rest, so that we get ground collisions properly
	    body.collisionEventMode = COLLISION_ALWAYS;

	    // Set a capsule shape for collision
	    CollisionShape@ shape = treeNode.CreateComponent("CollisionShape");
	    shape.SetConvexHull(object.model);
	    Bush tree;
	    tree.node = treeNode;
	    tree.lifetime = 10.0f + Random(5.0f);
	    tree.stage = 0;
	    tree.model = object;
	    CreateBerries(5 + RandomInt(10), tree);
	    trees.Push(tree);
		return treeNode;
	}

	void CreateBerries(int count, Bush@ parentTree)
	{
		for (uint i = 0; i < count; i++) {
			Node@ apple = scene_.CreateChild("Raspberry");
			apple.AddTag("Raspberry");
			Vector3 position = parentTree.node.position;
			position.x += -30.0f + Random(60.0f);
			position.z += -30.0f + Random(60.0f);
			position.y = NetworkHandler::terrain.GetHeight(position) + 0.2f;
			apple.worldPosition = position;

		    StaticModel@ object = apple.CreateComponent("StaticModel");
	    	object.model = cache.GetResource("Model", "Models/Models/Raspberry.mdl");

	    	apple.SetScale(0.8f + Random(0.5f));
	        object.castShadows = true;
	        object.materials[0] = cache.GetResource("Material", "Materials/Raspberry.xml");
	        object.materials[1] = cache.GetResource("Material", "Materials/TreeGreen.xml");
	        object.materials[2] = cache.GetResource("Material", "Materials/TreeGreen.xml");

	        // Create rigidbody, and set non-zero mass so that the body becomes dynamic
		    RigidBody@ body = apple.CreateComponent("RigidBody");
		    body.collisionLayer = 1;
		    body.mass = 0.1f;

		    // Set zero angular factor so that physics doesn't turn the character on its own.
		    // Instead we will control the character yaw manually
		    //body.angularFactor = Vector3::ZERO;

		    // Set the rigidbody to signal collision also when in rest, so that we get ground collisions properly
		    body.collisionEventMode = COLLISION_ALWAYS;

		    CollisionShape@ shape = apple.CreateComponent("CollisionShape");
		    shape.SetConvexHull(object.model);

		    parentTree.berries.Push(apple);
		}
	}

	void ReenableBerries(Bush tree)
	{
		for (uint i = 0; i < tree.berries.length; i++) {
			Node@ berry = tree.berries[i];
			Vector3 position = tree.node.position;
			position.x += -30.0f + Random(60.0f);
			position.z += -30.0f + Random(60.0f);
			position.y = NetworkHandler::terrain.GetHeight(position) + 0.2f;
			berry.worldPosition = position;
			berry.SetDeepEnabled(true);
		}
	}

	void HandleUpdate(StringHash eventType, VariantMap& eventData)
	{
		float timeStep = eventData["TimeStep"].GetFloat();
		for (uint i = 0; i < trees.length; i++) {
			Bush@ tree = trees[i];
			tree.lifetime -= timeStep;
			if (tree.lifetime < 0) {
				tree.stage++;
				tree.lifetime = 10.0f + Random(5.0f);
				if (tree.stage > 1) {
					tree.stage = 0;
				}
				if (tree.stage == 0) {

					tree.model.materials[1] = cache.GetResource("Material", "Materials/TreeGreen.xml");
				} else if (tree.stage == 1) {
					tree.model.materials[1] = cache.GetResource("Material", "Materials/TreeYellow.xml");
				}
			}
		}
	}
}