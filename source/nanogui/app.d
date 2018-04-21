import std.datetime : Clock;

import arsd.simpledisplay;
import arsd.nanovega;
import nanogui.arsdbackend : ArsdBackend;

void main () {
	
	auto backend = new ArsdBackend();

	import nanogui.screen : Screen;
	import nanogui.widget, nanogui.theme, nanogui.checkbox, nanogui.label, 
		nanogui.common, nanogui.window, nanogui.layout, nanogui.button,
		nanogui.popupbutton, nanogui.entypo, nanogui.popup, nanogui.vscrollpanel;

	// this is called just before our window will be shown for the first time.
	// we must create NanoVega context here, as it needs to initialize
	// internal OpenGL subsystem with valid OpenGL context.
	backend.visibleForTheFirstTime = ()
	{
		{
			auto window = new Window(backend.screen, "Button demo");
			window.position(Vector2i(15, 15));
			window.size = Vector2i(backend.screen.size.x - 30, backend.screen.size.y - 30);
			window.layout(new GroupLayout());

			new Label(window, "Push buttons", "sans-bold");

			auto checkbox = new CheckBox(window, "Checkbox #1", (bool value){ backend.simple_window.redrawOpenGlSceneNow(); });
			checkbox.position = Vector2i(100, 190);
			checkbox.size = checkbox.preferredSize(backend.nvg);
			checkbox.checked = true;

			auto label = new Label(window, "Label");
			label.position = Vector2i(100, 300);
			label.size = label.preferredSize(backend.nvg);

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
			auto window = new Window(backend.screen, "Button group example");
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
			auto window = new Window(backend.screen, "Yet another window");
			window.position(Vector2i(300, 15));
			window.layout(new GroupLayout());

			new Label(window, "Message dialog", "sans-bold");
			new CheckBox(window, "Checkbox #3", (bool value){ });

			window.tooltip = "Window with checkbox #3 tooltip";
		}

		{
			auto window = new Window(backend.screen, "Yet another window");
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

			auto window = new Window(backend.screen, "All Icons");
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
		backend.screen.performLayout(backend.nvg);
	};
	
	backend.run();
}