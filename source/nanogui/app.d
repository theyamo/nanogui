import std.datetime : Clock;

import arsd.simpledisplay;
import arsd.nanovega;

void main () {
	NVGContext nvg; // our NanoVega context
	// we need at least OpenGL3 with GLSL to use NanoVega,
	// so let's tell simpledisplay about that
	setOpenGLContextVersion(3, 0);
	// now create OpenGL window
	auto sdmain = new SimpleWindow(1000, 800, "NanoVega Simple Sample", OpenGlOptions.yes, Resizability.allowResizing);
	// we need to destroy NanoVega context on window close
	// stricly speaking, it is not necessary, as nothing fatal
	// will happen if you'll forget it, but let's be polite.
	// note that we cannot do that *after* our window was closed,
	// as we need alive OpenGL context to do proper cleanup.
	sdmain.onClosing = delegate () {
		nvg.kill;
	};

	import nanogui.screen : Screen;
	import nanogui.widget, nanogui.theme, nanogui.checkbox, nanogui.label, 
		nanogui.common, nanogui.window, nanogui.layout, nanogui.button,
		nanogui.popupbutton, nanogui.entypo, nanogui.popup, nanogui.vscrollpanel;

	Screen screen;

	// this is called just before our window will be shown for the first time.
	// we must create NanoVega context here, as it needs to initialize
	// internal OpenGL subsystem with valid OpenGL context.
	sdmain.visibleForTheFirstTime = delegate () {
		// yes, that's all
		nvg = nvgCreateContext();
		assert(nvg !is null, "cannot initialize NanoGui");

		screen = new Screen(sdmain.width, sdmain.height, Clock.currTime.stdTime);
		screen.theme = new Theme(nvg);

		{
			auto window = new Window(screen, "Button demo");
			window.position(Vector2i(15, 15));
			window.size = Vector2i(screen.size.x - 30, screen.size.y - 30);
			window.layout(new GroupLayout());

			new Label(window, "Push buttons", "sans-bold");

			auto checkbox = new CheckBox(window, "Checkbox #1", (bool value){ sdmain.redrawOpenGlSceneNow(); });
			checkbox.position = Vector2i(100, 190);
			checkbox.size = checkbox.preferredSize(nvg);
			checkbox.checked = true;

			auto label = new Label(window, "Label");
			label.position = Vector2i(100, 300);
			label.size = label.preferredSize(nvg);

			Popup popup;

			auto btn = new Button(window, "Button");
			btn.callback = () { 
				popup.children[0].visible = !popup.children[0].visible; 
				label.caption = popup.children[0].visible ? 
					"Popup label is visible" : "Popup label isn't visible";
			};

			auto popupBtn = new PopupButton(window, "PopupButton", Entypo.ICON_EXPORT);
			popup = popupBtn.popup;
	        popup.layout(new GroupLayout());
	        new Label(popup, "Arbitrary widgets can be placed here");
	        new CheckBox(popup, "A check box", null);

	        window.tooltip = "Button demo tooltip";
		}

		{
			auto window = new Window(screen, "Button group example");
			window.position(Vector2i(200, 15));
			window.layout(new GroupLayout());

			auto buttonGroup = ButtonGroup();

			auto btn = new Button(window, "RadioButton1");
			btn.flags = Button.Flags.RadioButton;
			btn.buttonGroup = buttonGroup;
			btn.tooltip = "Radio button ONE";
			buttonGroup ~= btn;

			btn = new Button(window, "RadioButton2");
			btn.flags = Button.Flags.RadioButton;
			btn.buttonGroup = buttonGroup;
			btn.tooltip = "Radio button TWO";
			buttonGroup ~= btn;

			btn = new Button(window, "RadioButton3");
			btn.flags = Button.Flags.RadioButton;
			btn.buttonGroup = buttonGroup;
			btn.tooltip = "Radio button THREE";
			buttonGroup ~= btn;

	        window.tooltip = "Radio button group tooltip";
		}

		{
			auto window = new Window(screen, "Yet another window");
			window.position(Vector2i(300, 15));
			window.layout(new GroupLayout());

			new Label(window, "Message dialog", "sans-bold");
			new CheckBox(window, "Checkbox #3", (bool value){ });

	        window.tooltip = "Window with checkbox #3 tooltip";
		}

		{
			auto window = new Window(screen, "Yet another window");
			window.position(Vector2i(400, 15));
			window.layout(new GroupLayout());

			new Label(window, "Message dialog", "sans-bold");
			new CheckBox(window, "Checkbox #4", (bool value){ });

	        window.tooltip = "Window with checkbox FOUR tooltip";
		}

		{
			int width      = 400;
			int half_width = width / 2;
			int height     = 200;

			auto window = new Window(screen, "All Icons");
			window.position(Vector2i(0, 400));
			window.fixedSize(Vector2i(width, height));

			// attach a vertical scroll panel
			auto vscroll = new VScrollPanel(window);
			vscroll.fixedSize(Vector2i(width, height));

			// vscroll should only have *ONE* child. this is what `wrapper` is for
			auto wrapper = new Widget(vscroll);
			wrapper.fixedSize(Vector2i(width, height));
			wrapper.layout(new GridLayout());// defaults: 2 columns

			foreach(i; 0..100)
			{
				import std.conv : text;
				auto item = new Button(wrapper, "item" ~ i.text, Entypo.ICON_AIRCRAFT_TAKE_OFF);
				item.iconPosition(Button.IconPosition.Left);
				item.fixedWidth(half_width);
			}
		}

		// now we should do layout manually yet
		screen.performLayout(nvg);
	};

	// this callback will be called when we will need to repaint our window
	sdmain.redrawOpenGlScene = () {
		screen.size = Vector2i(sdmain.width, sdmain.height);
		screen.draw(nvg);
	};
	sdmain.eventLoop(40,
		() {
			// unfortunately screen may be not initialized
			if (screen)
			{
				screen.currTime = Clock.currTime.stdTime;
				if (screen.needToDraw)
					sdmain.redrawOpenGlSceneNow();
			}
		},
		delegate (KeyEvent event)
		{
			if (event == "*-Q" || event == "Escape") { sdmain.close(); return; } // quit on Q, Ctrl+Q, and so on
		},
		delegate (MouseEvent event)
		{
			import std.datetime : Clock;
			import nanogui.common : MouseButton, MouseAction;

			MouseButton btn;
			MouseAction action;
			int modifiers;

			// convert event data from arsd.simpledisplay format
			// to own format
			switch(event.button)
			{
				case arsd.simpledisplay.MouseButton.left:
					btn = MouseButton.Left;
				break;
				case arsd.simpledisplay.MouseButton.right:
					btn = MouseButton.Right;
				break;
				case arsd.simpledisplay.MouseButton.middle:
					btn = MouseButton.Middle;
				break;
				case arsd.simpledisplay.MouseButton.wheelUp:
					btn = MouseButton.WheelUp;
					screen.scrollCallbackEvent(0, -1, Clock.currTime.stdTime);
				break;
				case arsd.simpledisplay.MouseButton.wheelDown:
					btn = MouseButton.WheelDown;
					screen.scrollCallbackEvent(0, 1, Clock.currTime.stdTime);
				break;
				default:
					btn = MouseButton.None;
			}

			final switch(event.type)
			{
				case arsd.simpledisplay.MouseEventType.buttonPressed:
					action = MouseAction.Press;
				break;
				case arsd.simpledisplay.MouseEventType.buttonReleased:
					action = MouseAction.Release;
				break;
				case arsd.simpledisplay.MouseEventType.motion:
					action = MouseAction.Motion;
					screen.cursorPosCallbackEvent(event.x, event.y, Clock.currTime.stdTime);
				return;
			}

			if (event.modifierState & ModifierState.leftButtonDown)
				modifiers |= MouseButton.Left;
			if (event.modifierState & ModifierState.rightButtonDown)
				modifiers |= MouseButton.Right;
			if (event.modifierState & ModifierState.middleButtonDown)
				modifiers |= MouseButton.Middle;

			// propagating button events
			if (event.type == MouseEventType.buttonPressed  ||
				event.type == MouseEventType.buttonReleased ||
				event.type == MouseEventType.motion)
			{
				screen.mouseButtonCallbackEvent(btn, action, modifiers, Clock.currTime.stdTime);
			}
		},
	);
	flushGui(); // let OS do it's cleanup
}