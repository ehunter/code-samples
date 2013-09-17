package com.litl.weather.view
{
    import com.litl.weather.WeatherChannel;
    import caurina.transitions.Tweener;
    import com.litl.weather.model.twc.Weather;
    import flash.display.MovieClip;

    /**
     * @author mkeefe
     */
    public class CardSlideView extends ViewManager
    {

        public var card:CardView = null;
        public var threeDay:CardViewThreeDay;

        public var viewingID:int = 0;

        private var animating:Boolean = false;

        public function CardSlideView() {

        }

        override public function updateView(weather:Weather):void {
            trace("CardSlideView::updateView()");

            //card.updateView(weather);
            //threeDay.updateView(weather);
            //
            //return;

            if (card == null) {
                card = new CardView();
                addChild(card);

                threeDay = new CardViewThreeDay();
                threeDay.x = card.width;
                threeDay.y = 0;
                addChild(threeDay);
            }

            card.updateView(weather);
            threeDay.updateView(weather);

            super.updateView(weather);

            //card['debug_txt'].text = weatherService.locations;

            //card.updateView(weather);
            //threeDay.updateView(weather);
            //slideNext();
        }

        public function slidePrev():void {
            if (animating)
                return;

            animating = true;

            if ((viewingID == 0) && (threeDay != null)) {
                threeDay.x = -card.width;
                Tweener.addTween(card, { x: card.width, y: 0, time: 1.2 });
                Tweener.addTween(threeDay, { x: 0, y: 0, time: 1.2, onComplete: cardSlideComplete });
            }
            else if (viewingID == 1) {
                card.x = -threeDay.width;
                Tweener.addTween(card, { x: 0, y: 0, time: 1.2 });
                Tweener.addTween(threeDay, { x: threeDay.width, y: 0, time: 1.2, onComplete: cardSlideComplete });
            }
        }

        public function slideNext():void {
            if (animating)
                return;

            animating = true;

            if ((viewingID == 0) && (threeDay != null)) {
                threeDay.x = card.width;
                Tweener.addTween(threeDay, { x: 0, y: 0, time: 1.2 });
                Tweener.addTween(card, { x: -card.width, y: 0, time: 1.2, onComplete: cardSlideComplete });
            }
            else if (viewingID == 1) {
                card.x = threeDay.width;
                Tweener.addTween(card, { x: 0, y: 0, time: 1.2 });
                Tweener.addTween(threeDay, { x: -threeDay.width, y: 0, time: 1.2, onComplete: cardSlideComplete });
            }

        }

        private function cardSlideComplete():void {
            animating = false;

            if (viewingID == 0)
                viewingID = 1;
            else if (viewingID == 1)
                viewingID = 0;
        }

    }
}
