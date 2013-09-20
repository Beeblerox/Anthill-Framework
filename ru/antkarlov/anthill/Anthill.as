package ru.antkarlov.anthill
{
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.display.StageScaleMode;
	import flash.display.StageAlign;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.events.MouseEvent;
	import flash.events.KeyboardEvent;
	import flash.utils.getTimer;
	import flash.ui.Mouse;
	
	import ru.antkarlov.anthill.debug.AntPerfomance;
	
	public class Anthill extends Sprite
	{
		//Flex v4.x SDK
		// Обычное подключение шрифта.
		//[Embed(source="resources/iFlash706.ttf",fontFamily="system",embedAsCFF="false")] protected var junk:String;
		
		// Обычное подключение шрифта с кирилицой.
		[Embed(source= "resources/iFlash706.ttf",fontFamily="system",embedAsCFF="false",
			unicodeRange="U+0020-U+002F,U+0030-U+0039,U+003A-U+0040,U+0041-U+005A,U+005B-U+0060,U+0061-U+007A,U+007B-U+007E,U+0400-U+04CE,U+2000-U+206F,U+20A0-U+20CF,U+2100-U+2183")] protected var junk:String;
		//*/
		
		//Flex v3.x SDK
		// Подключение шрифта.
		//[Embed(source="resources/iFlash706.ttf",fontFamily="system")] protected var junk:String;
		
		// Подключение шрифта с кирилицой.
		/*[Embed(source= "resources/iFlash706.ttf",fontFamily="system",mimeType="application/x-font",
			unicodeRange="U+0020-U+002F,U+0030-U+0039,U+003A-U+0040,U+0041-U+005A,U+005B-U+0060,U+0061-U+007A,U+007B-U+007E,U+0400-U+04CE,U+2000-U+206F,U+20A0-U+20CF,U+2100-U+2183")] protected var junk:String;
		//*/
		
		//---------------------------------------
		// PROTECTED VARIABLES
		//---------------------------------------
		
		/**
		 * Указатель на текущее игровое состояние.
		 */
		public var state:AntState;
		public var cameras:Array;
		
		//---------------------------------------
		// PROTECTED VARIABLES
		//---------------------------------------
		
		/**
		 * @private
		 */
		protected var _defaultCamera:AntCamera;
		
		/**
		 * Класс игрового состояния которое будет создано при инициализации.
		 */
		protected var _initialState:Class;
		
		/**
		 * Количество кадров в секунду при инициализации.
		 * @default    35
		 */
		protected var _frameRate:uint;
		
		/**
		 * Флаг определяющий инициализацию фреймворка.
		 * @default    false
		 */
		protected var _isCreated:Boolean;
		
		/**
		 * Флаг определяющий запуск процесса обработки фреймворка.
		 */
		protected var _isStarted:Boolean;
		
		/**
		 * Помошник для рассчета игрового времени.
		 */
		protected var _elapsed:Number;
		
		/**
		 * Помошник для рассчета игрового времени.
		 */
		internal var _total:uint;
		
		/**
		 * Указатель на сборщик информации о производительности.
		 */
		protected var _perfomance:AntPerfomance;
		
		/**
		 * Определяет используется в игре системный курсор или нет.
		 * @default    true
		 */
		internal var _useSystemCursor:Boolean;
		
		//---------------------------------------
		// CONSTRUCTOR
		//---------------------------------------
		
		/**
		 * @constructor
		 */
		public function Anthill(aInitialState:Class = null, aFrameRate:uint = 35, 
			aUseSystemCursor:Boolean = true)
		{
			super();
			
			_useSystemCursor = aUseSystemCursor;
			if (!_useSystemCursor)
			{
				flash.ui.Mouse.hide();
			}
			
			_initialState = aInitialState;
			_frameRate = aFrameRate;
			_isCreated = false;
			_isStarted = false;
			
			(stage == null) ? addEventListener(Event.ADDED_TO_STAGE, create) : create(null);
		}
		
		/**
		 * Инициализация фреймворка.
		 * 
		 * @param	event	 Стандартное события Flash.
		 */
		protected function create(event:Event):void
		{
			if (event != null)
			{
				removeEventListener(Event.ADDED_TO_STAGE, create);
			}
			
			AntG.init(this);
			_perfomance = AntG.debugger.perfomance;
			
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			stage.frameRate = _frameRate;
			
			stage.addEventListener(KeyboardEvent.KEY_DOWN, AntG.debugger.console.keyDownHandler);
			stage.addEventListener(KeyboardEvent.KEY_DOWN, AntG.keys.keyDownHandler);
			stage.addEventListener(KeyboardEvent.KEY_UP, AntG.keys.keyUpHandler);
			stage.addEventListener(MouseEvent.MOUSE_DOWN, AntG.mouse.mouseDownHandler);
			stage.addEventListener(MouseEvent.MOUSE_UP, AntG.mouse.mouseUpHandler);
			stage.addEventListener(MouseEvent.MOUSE_OUT, AntG.mouse.mouseOutHandler);
			stage.addEventListener(MouseEvent.MOUSE_OVER, AntG.mouse.mouseOverHandler);
			stage.addEventListener(MouseEvent.MOUSE_WHEEL, AntG.mouse.mouseWheelHandler);
			
			_perfomance.start();
			
			_isCreated = true;
			if (_initialState != null)
			{
				switchState(new _initialState());
				start();
			}
		}
		
		/**
		 * Запускает процессинг фреймворка.
		 */
		public function start():void
		{
			if (!_isStarted && _isCreated)
			{
				addEventListener(Event.ENTER_FRAME, enterFrameHandler);
				_isStarted = true;
			}
		}
		
		/**
		 * Останавливает процессинг фреймворка.
		 */
		public function stop():void
		{
			if (_isStarted && _isCreated)
			{
				removeEventListener(Event.ENTER_FRAME, enterFrameHandler);
				_isStarted = false;
			}
		}
		
		/**
		 * Переключает игровые состояния.
		 * 
		 * @param	aState	 Новое состояние на которое необходимо произвести переключение.
		 */
		public function switchState(aState:AntState):void
		{	
			addChild(aState);
			if (state != null)
			{
				state.destroy();
				swapChildren(state, aState);
				removeChild(state);
				
				if (_defaultCamera != null && AntG.camera == _defaultCamera)
				{
					AntG.removeCamera(_defaultCamera);
				}
			}

			state = aState;
			state.create();
			
			// Если камера не создана состоянием, создаем камеру по умолчанию.
			if (AntG.camera == null)
			{
				if (_defaultCamera == null)
				{
					_defaultCamera = new AntCamera(0, 0, AntG.width, AntG.height);
					_defaultCamera.fillBackground = true;
				}
				
				AntG.addCamera(_defaultCamera);
			}
			else if (AntG.camera != null && _defaultCamera != null && AntG.camera != _defaultCamera)
			{
				_defaultCamera.destroy();
				_defaultCamera = null;
			}
			
			if (!_isStarted)
			{
				start();
			}
		}
		
		//---------------------------------------
		// PROTECTED METHODS
		//---------------------------------------
		
		/**
		 * Основной обработчик.
		 */
		protected function enterFrameHandler(event:Event):void
		{
			// Рассчет времени между кадрами.
			var curTime:uint = getTimer();
			var elapsedMs:uint = curTime - _total;
			_perfomance.ratingTotal.add(elapsedMs);
			_elapsed = elapsedMs / 1000;
			_total = curTime;
			AntG.elapsed = (_elapsed > AntG.maxElapsed) ? AntG.maxElapsed : _elapsed;
			AntG.elapsed *= AntG.timeScale;
			
			// Процессинг.
			update();
			
			// Расчет времени ушедшего на процессинг.
			var updTime:uint = getTimer();
			_perfomance.ratingUpdate.add(updTime - curTime);
			
			// Рендер графического контента.
			render();
			
			// Рассчет времени ушедшего на рендер.
			var rndTime:uint = getTimer();
			_perfomance.ratingRender.add(rndTime - updTime);
			
			AntG.plugins.update();
			
			// Рассчет времени ушедшего на плагины.
			_perfomance.ratingPlugins.add(getTimer() - rndTime);
			AntG.debugger.update();
		}
		
		/**
		 * Выполняет процессинг содержимого игры.
		 */
		protected function update():void
		{
			AntG.updateInput();
			AntG.sounds.update();

			AntBasic.NUM_OF_ACTIVE = 0;
			AntEntity.DEPTH_ID = 0;
			if (state != null)
			{
				state.preUpdate();
				state.update();
				state.postUpdate();
			}
		}
		
		/**
		 * Выполняет рендеринг содержимого игры.
		 */
		protected function render():void
		{
			AntBasic.NUM_OF_VISIBLE = 0;
			AntBasic.NUM_ON_SCREEN = 0;
			
			if (cameras == null)
			{
				cameras = AntG.cameras;
			}
			
			var debugDraw:Boolean = (AntG.debugDrawer != null);
			var i:int = 0;
			var n:int = cameras.length;
			var camera:AntCamera;
			while (i < n)
			{
				camera = cameras[i++] as AntCamera;
				if (camera != null && camera.exists)
				{
					camera.update();
					
					if (debugDraw)
					{
						AntG.debugDrawer.buffer = camera.buffer;
					}
					
					camera.beginDraw();
					
					// Отрисовка содержимого для текущего состояния.
					if (state != null && state.defGroup.exists && state.defGroup.visible)
					{
						state.defGroup.draw(camera);
						if (debugDraw)
						{
							state.defGroup.debugDraw(camera);
						}
					}
					
					// Отрисовка плагинов.
					AntG.plugins.draw(camera);
					camera.endDraw();
					
					if (debugDraw)
					{
						AntG.debugDrawer.buffer = null;
					}
				}
			}
			
			AntG.mouse.draw();
		}

	}

}