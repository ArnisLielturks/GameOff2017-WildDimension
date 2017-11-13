namespace SplashScreen {

    Sprite@ logoSprite;
    float opacity; //current opacity
    bool show;
    const float FADE_SPEED = 1.0f; //How fast the logo should fade in and fade out
    bool ended = false;
    Array<String> textures;
    uint currentIndex = 0;

    /**
     * List of all the logos which we need to show in the splash screen
     */
    void InitList()
    {
        textures.Push("Textures/FishBoneLogo.png");
        textures.Push("Textures/UrhoIcon.png");
    }

    void SetTexture()
    {
        Destroy();
        logoSprite = ui.root.CreateChild("Sprite");
        Texture2D@ logoTexture = cache.GetResource("Texture2D", textures[currentIndex]);
        //if (logoTexture is null)
          //  return;

        // Set logo sprite texture
        logoSprite.texture = logoTexture;

        int textureWidth = logoTexture.width;
        int textureHeight = logoTexture.height;

        // Set logo sprite scale
        //logoSprite.SetScale(256.0f / textureWidth);

        // Set logo sprite size
        logoSprite.SetSize(textureWidth, textureHeight);

        logoSprite.position = Vector2(-textureWidth/2, -textureHeight/2);

        // Set logo sprite hot spot
        //logoSprite.SetHotSpot(textureWidth, textureHeight);

        // Set logo sprite alignment
        logoSprite.SetAlignment(HA_CENTER, VA_CENTER);
        //logoSprite.position = Vector2(-textureWidth/2, -textureHeight/2);

        // Make logo not fully opaque to show the scene underneath
        logoSprite.opacity = opacity;

        // Set a low priority for the logo so that other UI elements can be drawn on top
        logoSprite.priority = -100;
        //DelayedExecute(10.0, false, "void SplashScreen::HandleSplashEnd()");

    }

    void CreateSplashScreen()
    {
        InitList();
        opacity = 0.f;
        show = true;

        SubscribeToEvent("Update", "SplashScreen::HandleUpdate");

        SetTexture();
    }

    void Destroy()
    {
        if (logoSprite !is null) {
            logoSprite.Remove();
        }
    }

    void HandleSplashEnd()
    {
        Destroy();
        SendEvent("SplashScreenEnd");
    }

    void HandleUpdate(StringHash eventType, VariantMap& eventData)
    {
        float timeStep = eventData["TimeStep"].GetFloat();
        if (show) {
            opacity += timeStep * FADE_SPEED;
            if (opacity > 1.0f) {
                opacity = 1.0f;
                show = false;
            }
        } else if (!ended) {
            opacity -= timeStep * FADE_SPEED;
            if (opacity < 0.0f) {
                opacity = 0.0f;
                currentIndex++;
                if (currentIndex >= textures.length) {
                    ended = true;
                    HandleSplashEnd();
                } else {
                    show = true;
                    SetTexture();
                }
            }
        }
        logoSprite.opacity = opacity;
    }
}
