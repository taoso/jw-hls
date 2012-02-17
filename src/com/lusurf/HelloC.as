package com.lusurf {
	import flash.utils.setInterval;

	/**
	 * @author lusurf
	 */
	public class HelloC extends Hello {
		public function HelloC():void {
			setInterval(test,1000);
		};
		public function test():void {
			var dt:Date = new Date();
			_lc.send('_hello', 'test', dt.toString());
		}
	}
}
