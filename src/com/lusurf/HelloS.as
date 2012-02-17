package com.lusurf {
	import flash.external.ExternalInterface;
	import com.lusurf.Hello;
	/**
	 * @author lusurf
	 */
	public class HelloS extends Hello {
		public function HelloS():void {
			_lc.connect('_hello');
			_lc.client = this;
		}
		public function test(msg:String):void {
			ExternalInterface.call('console.log', msg);
		}
		
	}
}
