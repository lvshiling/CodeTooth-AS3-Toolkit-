package com.codeTooth.actionscript.game.agreement
{
	import com.codeTooth.actionscript.lang.exceptions.NullPointerException;
	import com.codeTooth.actionscript.lang.utils.destroy.DestroyUtil;
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	public class AgreementURLQueueLoader extends EventDispatcher implements IAgreementSourceLoader
	{
		private var _parser:IAgreementParser = null;
		
		public function AgreementURLQueueLoader(parser:IAgreementParser)
		{
			if(parser == null)
			{
				throw new NullPointerException("Null parser");
			}
			_parser = parser;
		}
		
		//----------------------------------------------------------------------------------------------------------------------------------
		// 实现 IAgreementSourceLoader 接口
		//----------------------------------------------------------------------------------------------------------------------------------
		
		private var _loader:URLLoader = null;
		
		private var _sources:Vector.<String> = null;
		
		private var _currSourceIndex:uint = 0;
		
		private var _datas:Vector.<Object> = null;
		
		private var _xml:XML = null;
		
		public function load(source:Object):void
		{
			if(_loader == null)
			{
				_loader = new URLLoader();
			}
			_datas = new Vector.<Object>();
			_currSourceIndex = 0;
			close();
			addLoaderListeners();
			_sources = Vector.<String>(source);
			loadInner();
		}
		
		public function close():void
		{
			if(_loader != null)
			{
				removeLoaderListeners();
				try
				{
					_loader.close();
				}
				catch(error:Error)
				{
					// Do nothing
				}
			}
		}
		
		public function getAgreementXML():XML
		{
			return _xml;
		}
		
		private function loadInner():void
		{
			if(_sources == null || _currSourceIndex >= _sources.length)
			{
				close();
				
				_xml = _parser.parse(_datas);
				
				var newEvent:AgreementEvent = new AgreementEvent(AgreementEvent.COMPLETE);
				newEvent.source = _sources;
				dispatchEvent(newEvent);
			}
			else
			{
				_loader.load(new URLRequest(String(_sources[_currSourceIndex])));
			}
		}
		
		private function addLoaderListeners():void
		{
			_loader.addEventListener(Event.COMPLETE, completeHandler);
			_loader.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			_loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
		}
		
		private function removeLoaderListeners():void
		{
			_loader.removeEventListener(Event.COMPLETE, completeHandler);
			_loader.removeEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			_loader.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler);
		}
		
		private function completeHandler(event:Event):void
		{
			_datas[_currSourceIndex] = _loader.data;
			_currSourceIndex++;
			loadInner();
		}
		
		private function ioErrorHandler(event:IOErrorEvent):void
		{
			close();
			dispatchEventInner(AgreementEvent.IO_ERROR);
		}
		
		private function securityErrorHandler(event:SecurityErrorEvent):void
		{
			close();
			dispatchEventInner(AgreementEvent.SECURITY_ERROR);
		}
		
		private function dispatchEventInner(type:String):void
		{
			var newEvent:AgreementEvent = new AgreementEvent(type);
			newEvent.source = _sources[_currSourceIndex];
			dispatchEvent(newEvent);
		}
		
		private function destroyLoader():void
		{
			if(_loader != null)
			{
				close();
				_loader = null;
			}
		}
		
		//----------------------------------------------------------------------------------------------------------------------------------
		// 实现 IDestroy 接口
		//----------------------------------------------------------------------------------------------------------------------------------
		
		public function destroy():void
		{
			destroyLoader();
			_xml = null;
			_sources = null;
			DestroyUtil.breakVector(_datas);
			_datas = null;
		}
	}
}