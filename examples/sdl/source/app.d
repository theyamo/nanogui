module examples.sdl;

import std.datetime : Clock;
import arsd.nanovega;
import nanogui.sdlbackend : SdlBackend;
import nanogui.widget : Widget;
import nanogui.glcanvas : GLCanvas;

struct Vertex
{
	import nanogui.common;
	Vector3f position;
	Vector3f color;
}

extern(C)
uint timer_callback(uint interval, void *param) nothrow
{
	import gfm.sdl2;

    SDL_Event event;
    SDL_UserEvent userevent;

    userevent.type = SDL_USEREVENT;
    userevent.code = 0;
    userevent.data1 = null;
    userevent.data2 = null;

    event.type = SDL_USEREVENT;
    event.user = userevent;

    SDL_PushEvent(&event);
    return(interval);
}

class MyGlCanvas : GLCanvas
{
	import std.typecons : scoped;
	import gfm.opengl;
	import gfm.math;
	import nanogui.common;

	this(Widget parent, OpenGL gl)
	{
		super(parent);

		_gl = gl;

		const program_source = 
			"#version 130

			#if VERTEX_SHADER
			uniform mat4 modelViewProj;
			in vec3 position;
			in vec3 color;
			out vec4 frag_color;
			void main() {
				frag_color  = modelViewProj * vec4(0.5 * color, 1.0);
				gl_Position = modelViewProj * vec4(position / 2, 1.0);
			}
			#endif

			#if FRAGMENT_SHADER
			out vec4 color;
			in vec4 frag_color;
			void main() {
				color = frag_color;
			}
			#endif";

		_program = new GLProgram(_gl, program_source);
		assert(_program);
		auto vert_spec = scoped!(VertexSpecification!Vertex)(_program);
		_rotation = Vector3f(0.25f, 0.5f, 0.33f);

		int[12*3] indices =
		[
			0, 1, 3,
			3, 2, 1,
			3, 2, 6,
			6, 7, 3,
			7, 6, 5,
			5, 4, 7,
			4, 5, 1,
			1, 0, 4,
			4, 0, 3,
			3, 7, 4,
			5, 6, 2,
			2, 1, 5,
		];

		auto vertices = 
		[
			Vertex(Vector3f(-1,  1,  1), Vector3f(1, 0, 0)),
			Vertex(Vector3f(-1,  1, -1), Vector3f(0, 1, 0)),
			Vertex(Vector3f( 1,  1, -1), Vector3f(1, 1, 0)),
			Vertex(Vector3f( 1,  1,  1), Vector3f(0, 0, 1)),
			Vertex(Vector3f(-1, -1,  1), Vector3f(1, 0, 1)),
			Vertex(Vector3f(-1, -1, -1), Vector3f(0, 1, 1)),
			Vertex(Vector3f( 1, -1, -1), Vector3f(1, 1, 1)),
			Vertex(Vector3f( 1, -1,  1), Vector3f(0.5, 0.5, 0.5)),
		];

		auto vbo = scoped!GLBuffer(gl, GL_ARRAY_BUFFER, GL_STATIC_DRAW, vertices);
		auto ibo = scoped!GLBuffer(gl, GL_ELEMENT_ARRAY_BUFFER, GL_STATIC_DRAW, indices);

		_vao = scoped!GLVAO(gl);
		// prepare VAO
		{
			_vao.bind();
			vbo.bind();
			ibo.bind();
			vert_spec.use();
			_vao.unbind();
		}

		{
			import gfm.sdl2 : SDL_AddTimer;
			uint delay = 40;
			_timer_id = SDL_AddTimer(delay, &timer_callback, null);
		}
	}

	~this()
	{
		import gfm.sdl2 : SDL_RemoveTimer;
		SDL_RemoveTimer(_timer_id);
	}

	override void drawGL()
	{
		static long start_time;
		mat4f mvp;
		mvp = mat4f.identity;

		if (start_time == 0)
			start_time = Clock.currTime.stdTime;

		auto angle = (Clock.currTime.stdTime - start_time)/10_000_000.0;
		mvp = mvp.rotation(angle, _rotation);

		GLboolean depth_test_enabled;
		glGetBooleanv(GL_DEPTH_TEST, &depth_test_enabled);
		if (!depth_test_enabled)
			glEnable(GL_DEPTH_TEST);
		scope(exit)
		{
			if (!depth_test_enabled)
				glDisable(GL_DEPTH_TEST);
		}

		_program.uniform("modelViewProj").set(mvp);
		_program.use();
		scope(exit) _program.unuse();

		_vao.bind();
		glDrawElements(GL_TRIANGLES, 36, GL_UNSIGNED_INT, cast(void *) 0);
		_vao.unbind();
	}

private:
	OpenGL    _gl;
	GLProgram _program;
	Vector3f  _rotation;

	import gfm.sdl2 : SDL_TimerID;
	SDL_TimerID _timer_id;

	import std.typecons : scoped;
	import gfm.opengl : GLVAO;

	alias ScopedGLVAO = typeof(scoped!GLVAO(OpenGL.init));
	ScopedGLVAO    _vao;
}

class MyGui : SdlBackend
{
	this(int w, int h, string title)
	{
		super(w, h, title);
	}

	override void onVisibleForTheFirstTime()
	{
		import nanogui.screen : Screen;
		import nanogui.widget, nanogui.theme, nanogui.checkbox, nanogui.label, 
			nanogui.common, nanogui.window, nanogui.layout, nanogui.button,
			nanogui.popupbutton, nanogui.entypo, nanogui.popup, nanogui.vscrollpanel,
			nanogui.combobox, nanogui.textbox;
		
		{
			auto window = new Window(screen, "Button demo");
			window.position(Vector2i(15, 15));
			window.size = Vector2i(screen.size.x - 30, screen.size.y - 30);
			window.layout(new GroupLayout());

			new Label(window, "Push buttons", "sans-bold");

			auto checkbox = new CheckBox(window, "Checkbox #1", null);
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
			window.position(Vector2i(220, 15));
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
			auto window = new Window(screen, "Button with image window");
			window.position(Vector2i(400, 15));
			window.layout(new GroupLayout());

			auto image = nvg.createImage("resources/icons/start.jpeg", [NVGImageFlags.ClampToBorderX, NVGImageFlags.ClampToBorderY]);
			auto btn = new Button(window, "Start", image);
			// some optional height, not font size, not icon height
			btn.fixedHeight = 130;

			// yet another Button with the same image but default size
			new Button(window, "Start", image);

			window.tooltip = "Window with button that has image as an icon";
		}

		{
			auto window = new Window(screen, "Combobox window");
			window.position(Vector2i(600, 15));
			window.layout(new GroupLayout());

			new Label(window, "Message dialog", "sans-bold");
			import std.algorithm : map;
			import std.range : iota;
			import std.array : array;
			import std.conv : text;
			auto items = 15.iota.map!(a=>text("items", a)).array;
			auto cb = new ComboBox(window, items);
			cb.cursor = Cursor.Hand;
			cb.tooltip = "This widget has custom cursor value - Cursor.Hand";

			window.tooltip = "Window with ComboBox tooltip";
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

		{
			auto asian_theme = new Theme(nvg);

			{
				// sorta hack because loading font in nvg results in
				// conflicting font id
				auto nvg2 = nvgCreateContext(NVGContextFlag.Debug);
				scope(exit) nvg2.kill;
				nvg2.createFont("chihaya", "./resources/fonts/n_chihaya_font.ttf");
				nvg.addFontsFrom(nvg2);
				asian_theme.mFontNormal = nvg.findFont("chihaya");
			}

			auto window = new Window(screen, "Textbox window");
			window.position = Vector2i(750, 15);
			window.fixedSize = Vector2i(200, 350);
			window.layout(new GroupLayout());
			window.tooltip = "Window with TextBoxes";

			auto tb = new TextBox(window, "Россия");
			tb.editable = true;

			tb = new TextBox(window, "England");
			tb.editable = true;

			tb = new TextBox(window, "日本");
			tb.theme = asian_theme;
			tb.editable = true;

			tb = new TextBox(window, "中国");
			tb.theme = asian_theme;
			tb.editable = true;
		}

		{
			auto window = new Window(screen, "GLCanvas Demo");
			window.position = Vector2i(450, 400);
			window.layout = new GroupLayout();
			auto glcanvas = new MyGlCanvas(window, gl);
			glcanvas.size = Vector2i(300, 300);
			glcanvas.backgroundColor = Color(0.1f, 0.1f, 0.1f, 1.0f);
		}
		
		// now we should do layout manually yet
		screen.performLayout(nvg);
	}
}

void main () {
	
	auto gui = new MyGui(1000, 800, "Nanogui using SDL2 backend");
	gui.run();
}