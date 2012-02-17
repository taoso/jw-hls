package com.lusurf {
	import flash.events.StatusEvent;
	import flash.display.Sprite;
	import flash.net.LocalConnection;
	/**
	 * @author lusurf
	 */
	public class Hello extends Sprite {
		public var _lc:LocalConnection;
		public function Hello() {
			_lc = new LocalConnection();
			_lc.addEventListener(StatusEvent.STATUS, _localConnectionEventHandler);
		};
		private static function _localConnectionEventHandler(evt:StatusEvent):void{};
	}
}
