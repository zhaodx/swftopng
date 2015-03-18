package
{
	import com.adobe.images.PNGEncoder;
	
	import flash.display.BitmapData;
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.display.StageQuality;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileStream;
	import flash.geom.Matrix;
	import flash.net.FileFilter;
	import flash.net.URLRequest;
	import flash.system.ApplicationDomain;
	import flash.system.LoaderContext;
	import flash.text.TextField;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import flash.geom.Rectangle;
	
	[SWF(width='500', height='300')]
	
	public class Pngs extends Sprite
	{
		private var 
			_timer         : Timer,
			_panel         : Sprite,
			_loader        : Loader,
			_prefix        : String,
			_counter       : int,
			_loadInfo      : LoaderInfo,
			_loadedSwf     : MovieClip,
			_swfLoader     : Loader,
			_swfpathTxt    : TextField,
			_fileToOpen    : File,
			_scaleFactor   : Number,
			_totalFrames   : int,
			_inputFileName : String,
			_inputFilePath : String,
			_outputDirPath : String;
					
		
		public function Pngs()
		{
			if (stage)
			{
				init();
			}else
			{
				addEventListener(Event.ADDED_TO_STAGE, init);
			}
		}
		
		private function init():void
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
			stage.quality = StageQuality.BEST;
			stage.addEventListener(Event.RESIZE, onResize, false, 0, true);
			
			_loader = new Loader();
			_loader.load(new URLRequest('/assets/asset.swf'), new LoaderContext(false, ApplicationDomain.currentDomain));
			_loader.contentLoaderInfo.addEventListener(Event.COMPLETE, onLoaderComp);
		}
		
		private function onResize(event:Event):void
		{
			if (_panel)
			{
				_panel.x = (stage.stageWidth - _panel.width) >> 1;
				_panel.y = (stage.stageHeight - _panel.height) >> 1;
			}
		}
		
		private function onLoaderComp(event:Event):void
		{
			_loader.contentLoaderInfo.removeEventListener(Event.COMPLETE, onLoaderComp);
			_loadInfo = event.currentTarget as LoaderInfo;
			
			createPanel();
		}
		
		private function createPanel():void
		{
			var cls:Class = getAssetClass('swfaspng_panel');
			
			if (cls)
			{
				_panel = new cls();
				
				addChild(_panel);
				onResize(null);
				
				var loadBtn:MovieClip = _panel.getChildByName('loadBtn') as MovieClip;
				loadBtn.buttonMode = true;
				loadBtn.mouseChildren = false;
				loadBtn.gotoAndStop(1);
				loadBtn.addEventListener(MouseEvent.CLICK, loadBtnClick);
				loadBtn.addEventListener(MouseEvent.MOUSE_OVER, btnHandler);
				loadBtn.addEventListener(MouseEvent.MOUSE_OUT, btnHandler);
				
				var exportBtn:MovieClip = _panel.getChildByName('exportBtn') as MovieClip;
				exportBtn.buttonMode = true;
				exportBtn.mouseChildren = false;
				exportBtn.gotoAndStop(1);
				exportBtn.addEventListener(MouseEvent.CLICK, exportBtnClick);
				exportBtn.addEventListener(MouseEvent.MOUSE_OVER, btnHandler);
				exportBtn.addEventListener(MouseEvent.MOUSE_OUT, btnHandler);
				
				_swfpathTxt = _panel.getChildByName('swfpathTxt') as TextField;
				_swfpathTxt.text = 'swf path';
			}
		}
		
		private function loadBtnClick(event:MouseEvent):void
		{
			var btn:MovieClip = event.target as MovieClip;
			
			if (btn)
			{
				if (btn.currentFrame > 2) return;
				
				_fileToOpen = File.documentsDirectory;
				selectTextFile(_fileToOpen);
			}
		}
		
		private function exportBtnClick(event:MouseEvent):void
		{
			var btn:MovieClip = event.target as MovieClip;
			
			if (btn)
			{
				if (btn.currentFrame > 2) return;
				
				loadSwf();
			}
		}
		
		private function btnHandler(event:MouseEvent):void
		{
			var btn:MovieClip = event.target as MovieClip;
			
			if (btn)
			{
				if (btn.currentFrame > 2) return;
				
				if(event.type == MouseEvent.MOUSE_OVER)
				{
					btn.gotoAndStop(2);
				}else
				{
					btn.gotoAndStop(1);
				}
			}
		}
		
		private function getAssetClass(name:String):Class
		{
			if (name && _loadInfo)
			{
				return _loadInfo.applicationDomain.getDefinition(name) as Class;
			}
			
			return null;
		}
		
		private function selectTextFile(root:File):void
		{
			var txtFilter:FileFilter = new FileFilter('Text', '*.swf');
			root.browseForOpen('Open', [txtFilter]);
			root.addEventListener(Event.SELECT, fileSelected);
		}
		
		private function fileSelected(event:Event):void
		{
			_inputFilePath = getInputFile(_fileToOpen.nativePath);
			_outputDirPath = getOutputDir();
			_scaleFactor = getScaleFactor();
			
			trace('Input file: ' + _inputFilePath);
			trace('Output directory: ' + _outputDirPath);
			
			_swfpathTxt.text = _inputFilePath;
		}
		
		private function loadSwf():void 
		{
			_swfLoader = new Loader();
			_swfLoader.load(new URLRequest("file://" + _inputFilePath));
			_swfLoader.contentLoaderInfo.addEventListener(Event.INIT, startLoop);
			
		}
		
		private function startLoop(ev:Event):void 
		{
			try 
			{
				_loadedSwf = MovieClip(ev.target.content).getChildAt(0) as MovieClip;
			}catch(err:Error) 
			{
				trace('AVM1 Movie not supported');
				return;
			}
			
			trace('Loaded!');
			
			_totalFrames = _loadedSwf.totalFrames;
			trace('Frame count: ' + _totalFrames);
			
			stopClip(_loadedSwf);
			goToFrame(_loadedSwf, 0);
			
			_timer = new Timer(1);
			_timer.addEventListener(TimerEvent.TIMER, step);
			_timer.start();
		}
		
		private function step(ev:TimerEvent):void 
		{
			_counter++;
			if(_counter <= _totalFrames) {
				goToFrame(_loadedSwf, _counter);
				saveFrame();
			}
			else {
				_timer.stop();
				_swfpathTxt.text = 'Done!';
				trace(_swfpathTxt.text);
				
				return;
			}
		}
		
		private function saveFrame():void
		{
			var matrix:Matrix = new Matrix(); 
			var bounds:Rectangle = _swfLoader.getBounds(_swfLoader);
			
			var bitmapData:BitmapData = new BitmapData(bounds.width * _scaleFactor, bounds.height * _scaleFactor, true, 0x0);
			matrix.translate(-bounds.x, -bounds.y);
			matrix.scale(_scaleFactor, _scaleFactor);
			bitmapData.draw(_swfLoader, matrix, null, null, bitmapData.rect, true);
			
			var bytearr:ByteArray = PNGEncoder.encode(bitmapData);
			var increment:String = '';
			
			if(_totalFrames > 1) 
			{
				increment = '_' + padNumber(_counter, _totalFrames);
			}
			
			var outfileName:String = _outputDirPath + File.separator + _prefix + increment + '.png';
			var file:File = new File(outfileName);
			
			_swfpathTxt.text = _prefix + increment + '.png';
			trace('Writing: ' + outfileName);
			
			var stream:FileStream = new FileStream();
			stream.open(file, "write");
			stream.writeBytes(bytearr);
			stream.close();
		}
		
		private function padNumber(input:int, target:int):String
		{
			var out:String = input.toString();
			var targetCount:int = target.toString().length;
			
			while(out.length < targetCount)
			{
				out = '0' + out;
			}
			
			return out;
		}
		
		private function getScaleFactor():Number
		{
			_scaleFactor = 1;
			
			return _scaleFactor;
		}
		
		private function stopClip(inMc:MovieClip):void 
		{
			var mc:MovieClip;
			var childNum:int = inMc.numChildren;
			
			for (var i:int = 0; i < childNum; i++) 
			{
				mc = inMc.getChildAt(i) as MovieClip;
				
				if(mc) 
				{
					mc.stop();
					
					if(mc.numChildren > 0) 
					{
						stopClip(mc);
					}
				}
			}
			
			inMc.stop();
		}
		
		private function goToFrame(inMc:MovieClip, frameNo:int):void 
		{
			var mc:MovieClip;
			var childNum:int = inMc.numChildren;
			
			for (var i:int = 0; i < childNum; i++) 
			{
				mc = inMc.getChildAt(i) as MovieClip;
				
				if(mc) 
				{
					mc.gotoAndStop(frameNo % (inMc.totalFrames + 1));
					
					if(mc.numChildren > 0) 
					{
						goToFrame(mc, frameNo);
					}
				}
			}
			
			inMc.gotoAndStop(frameNo % inMc.totalFrames);
		}
		
		private function getInputFile(path:String):String 
		{
			_inputFileName = path;
			
			var matchNameRegExStr:String = '([^\\' + File.separator + ']+)$';
			var matchNameRegEx:RegExp = new RegExp(matchNameRegExStr);
			var matches:Array = _inputFileName.match(matchNameRegEx);
			
			if(!matches)
			{
				trace('File inputFileName not valid');
				return '';
			}
			
			_prefix = matches[1].split('.')[0];
			
			trace('Prefix: ' + _prefix);
			
			var f:File = new File(path);
			f = f.resolvePath(_inputFileName);
			
			if(!f.exists)
			{
				trace('Input file not found!');
				return '';
			}
			
			return f.nativePath;
		}
		
		private function getOutputDir():String 
		{
			var d:File;
			
			if(_inputFilePath)
			{
				d = new File(_inputFilePath);
				
				if(!d.isDirectory)
				{
					d = d.resolvePath('..');
				}
				
				return d.nativePath + '/' + _prefix + '_pngs';
			}
			
			return '';
		}
	}
}