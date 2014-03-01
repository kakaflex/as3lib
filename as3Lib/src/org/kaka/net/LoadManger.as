package org.kaka.net
{
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLRequest;
	
	import org.kaka.ds.HashMap;

	/**
	 * 图片加载器
	 *   	(单线程.列队加载)
	 * @author kaka
	 * @Date 2014.2.25
	 */
	public class LoadManger
	{
		//图片缓存列表
		private static var imgList:HashMap=new HashMap();
		//加载队列列表
		private static var loadInfoLsit:HashMap=new HashMap();
		//是否正在加载
		private static var isLoading:Boolean=false;
		
		public function LoadManger()
		{
		}
		
		/**
		 * 初始化加载器
		 */
		public static function init():void
		{
		}
		
		/**
		 * @param url
		 * @param onComplete
		 */
		public static function load(url:String,onComplete):void
		{
			var loadInfo:LoadInfo=imgList.getValue(url);
			if(loadInfo!=null)
			{
				onComplete(loadInfo);
				trace("缓存数据:"+loadInfo.url);
				return;
			}
			var newInfo:LoadInfo=new LoadInfo();
			newInfo.url=url;
			newInfo.onComplete=onComplete;
			enqueue(newInfo);
		}
		
		public static function enqueue(loadInfo:LoadInfo):void
		{
			//如果当前线程正在加载，先缓存入列
			if(!isLoading)
				startLoad(loadInfo);
			loadInfoLsit.add(loadInfo.url,loadInfo);
		}
		
		private static function startLoad(loadInfo:LoadInfo):void
		{
			if(loadInfo)
			{
				var imgLoader:Loader=new Loader();
				imgLoader.contentLoaderInfo.addEventListener(Event.COMPLETE,loadComplete);
				imgLoader.contentLoaderInfo.addEventListener(IOErrorEvent.IO_ERROR,IOError);
				imgLoader.name=loadInfo.url;
				imgLoader.load(new URLRequest(loadInfo.url));
				trace("开始加载  : "+loadInfo.url);
				isLoading=true;
			}else
			{
				trace("加载完毕.");
			}
		}
		
		/**
		 * 加载完成处理
		 */
		private static function loadComplete(evt:Event):void
		{
			isLoading=false;
			
			try
			{
				var imgLoader:Loader=(evt.target as LoaderInfo).loader;
				var loadInfo:LoadInfo=loadInfoLsit.getValue(imgLoader.name);
				loadInfo.cache=(imgLoader.content as Bitmap).bitmapData.clone();
				imgList.add(imgLoader.contentLoaderInfo.url,loadInfo);
				loadInfo.onComplete.call(null,loadInfo);
				
				loadInfoLsit.remove(imgLoader.name);
				destroy(imgLoader);
				trace("加载完毕 : "+imgLoader.name);
			}
			catch(e:Error)
			{
				trace("错误 : "+e.message);
			}
			finally
			{
				startLoad(dequeue());
			}
		}
		
		protected static function IOError(event:IOErrorEvent):void
		{
			try
			{
				var imgLoader:Loader=(event.target as LoaderInfo).loader;
				var loadInfo:LoadInfo=loadInfoLsit.getValue(imgLoader.name);
				loadInfo.onComplete.call(null,loadInfo);
				
				loadInfoLsit.remove(imgLoader.name);
				destroy(imgLoader);
				trace("加载失败 : "+imgLoader.name);
			}
			catch(e:Error)
			{
				trace("错误 : "+e.message);
			}
			finally
			{
				startLoad(dequeue());
			}
		}
		
		private static function destroy(imgLoader:Loader):void
		{
			//destroy
			imgLoader.unload();
			imgLoader.contentLoaderInfo.removeEventListener(Event.COMPLETE,loadComplete);
			imgLoader.contentLoaderInfo.removeEventListener(IOErrorEvent.IO_ERROR,IOError);
			imgLoader=null;
		}
		
		/**
		 * 弹出加载队列
		 */
		private static function dequeue():LoadInfo
		{
			return loadInfoLsit.getValues().shift();
		}
	}
}