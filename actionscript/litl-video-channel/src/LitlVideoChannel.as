package
{

    import com.litl.control.playerclasses.YouTubeResource;
    import com.litl.skin.DefaultSkin;
    import com.litl.skin.StyleManager;
    import com.litl.tv.controller.AppController;
    import com.litl.tv.renderer.SlideshowDataRenderer;
    import com.litl.tv.view.MainView;
    import com.litl.sdk.enum.*;
    import com.litl.sdk.enum.PropertyScope;
    import com.litl.sdk.message.*;
    import com.litl.sdk.model.ChannelProperties;

    import flash.display.Sprite;
    import flash.display.StageAlign;
    import flash.display.StageScaleMode;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.system.Security;

    /**
     *
     */
    [SWF(backgroundColor = "0", frameRate = "30", width = "1280", height = "800")]
    public class LitlVideoChannel extends Sprite
    {

        /**
         * Embed some styles in a css stylesheet. We can instantiate this and plug it into our StyleManager.
         * Note the mimeType is application/octet-stream.
         */
        [Embed(source = "styles.css", mimeType = "application/octet-stream")]
        private static var skinCSS:Class;

        public function LitlVideoChannel() {

            // Set up the stage as noScale, aligned top-left.
            stage.scaleMode = StageScaleMode.NO_SCALE;
            stage.align = StageAlign.TOP_LEFT;

            initialize();
        }

        private function initialize():void {
            // Allow the player to communicate with our sandbox.
            flash.system.Security.allowDomain("http://netstorage.discovery.com");
            //flash.system.Security.allowInsecureDomain("http://netstorage.discovery.com/feeds/litl/");
            //flash.system.Security.allowDomain("https://s3.amazonaws.com/litl-channel-assets/discovery/");
            flash.system.Security.allowInsecureDomain("https://s3.amazonaws.com");
            flash.system.Security.allowDomain("*");

            // Add our stylesheet.
            StyleManager.getInstance().addEmbeddedStylesheet(skinCSS);

            // Create the main view and controller.
            var mainView:MainView = addChild(new MainView()) as MainView;
            mainView.tabChildren = false;
            mainView.tabEnabled = false;
            var appController:AppController = new AppController(mainView);

        }

    }
}
