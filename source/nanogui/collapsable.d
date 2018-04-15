module nanogui.collapsable;

import nanogui.widget;
import nanogui.common;
import nanogui.theme;

class Collapsable : Widget 
{
public:
	this(Widget parent, string caption, string font = "sans", int fontSize = -1)
	{
		super(parent);
		mCollapsed = true;
		mCaption = caption;
		mFont = font;
		if (mTheme) {
			mFontSize = mTheme.mStandardFontSize;
			mColor = mTheme.mTextColor;
		}
		if (fontSize >= 0) mFontSize = fontSize;

		import std.conv : text;
		mItems.length = 10_000_0;
		foreach(i; 0..mItems.length)
			mItems[i] = i.text;
	}

	/// Get the label's text caption
	final string caption() const { return mCaption; }
	/// Set the label's text caption
	final void caption(string caption) { mCaption = caption; }

	/// Set the currently active font (2 are available by default: 'sans' and 'sans-bold')
	final void font(string font) { mFont = font; }
	/// Get the currently active font
	final string font() const { return mFont; }

	/// Get the label color
	final Color color() const { return mColor; }
	/// Set the label color
	final void color(Color color) { mColor = color; }

	/// Set the \ref Theme used to draw this widget
	override void theme(Theme theme)
	{
		Widget.theme(theme);
		if (mTheme) {
			mFontSize = mTheme.mStandardFontSize;
			mColor = mTheme.mTextColor;
		}
	}

	/// Compute the size needed to fully display the label
	override Vector2i preferredSize(NVGContext nvg) const
	{
		if (mCaption == "")
			return Vector2i();
		nvg.fontFace(mFont);
		nvg.fontSize(fontSize());
		
		Vector2i result = void;

		float[4] bounds;
		if (mFixedSize.x > 0) {
			NVGTextAlign algn;
			algn.left = true;
			algn.top = true;
			nvg.textAlign(algn);
			nvg.textBoxBounds(mPos.x, mPos.y, mFixedSize.x, mCaption, bounds);
			auto h = cast(int) (bounds[3] - bounds[1]);
			result = Vector2i(
				cast(int)(mFixedSize.x + h*1.5f), 
				h
			);
		} else {
			NVGTextAlign algn;
			algn.left = true;
			algn.middle = true;
			nvg.textAlign(algn);
			result = Vector2i(
				cast(int) (nvg.textBounds(0, 0, mCaption, bounds) + 2 + fontSize() * 1.5f),
				fontSize
			);
			if (!mCollapsed)
				result.y += mItems.length * fontSize;
		}

		return result;
	}

	/// Draw the label
	override void draw(NVGContext nvg)
	{
		if (mUpdateLayout)
			screen.performLayout(nvg);

		Widget.draw(nvg);

		nvg.strokeWidth(1.0f);
		nvg.beginPath;
		nvg.rect(mPos.x - 0.5f, mPos.y - 0.5f, mSize.x + 1, mSize.y + 1);
		nvg.strokeColor(Color(220, 220, 220, 220));
		nvg.stroke;

		nvg.fontFace(mFont);
		nvg.fontSize(fontSize);
		nvg.fillColor(mColor);
		
		Vector2f iconPos;
		NVGTextAlign algn;
		algn.left = true;
		algn.top = true;
		nvg.textAlign(algn);
		float y = mPos.y;
		nvg.text(mPos.x + 1.25*fontSize, y, mCaption);
		iconPos.y = y + fontSize * 0.5f;

		// draw items if not collapsed
		if (!mCollapsed)
		{
			auto mouse_over = contains(screen.mousePos - parent.absolutePosition);

			foreach(item; mItems)
			{
				y += fontSize * 1.0f;
				if (y > screen.height)
					break;

				auto mouse = screen.mousePos - parent.absolutePosition;
				if (mouse_over && mouse.y > y && mouse.y < y + fontSize)
				{
					auto paint = nvg.boxGradient(mPos.x, y, mSize.x, y + fontSize, 
						2, 4, Color(0, 0, 220, 25), Color(0, 0, 128, 25));

					nvg.beginPath;
					nvg.roundedRect(mPos.x, y, mSize.x, fontSize, 2);

					nvg.fillPaint = paint;
					// now fill our rect
					nvg.fill();
				}
				nvg.fillColor(mColor);
				nvg.text(mPos.x + 2.5*fontSize, y, item);
			}
		}

		// draw icon
		{
			const tw = nvg.textBounds(0,0, mCaption, null);

			float iw, ih = fontSize;
			ih *= icon_scale();
			nvg.fontSize(ih);
			nvg.fontFace("icons");
			iw = nvg.textBounds(0.0f, 0.0f, mCollapsed ? iconCollapsed[] : iconUncollapsed[], null);

			if (mCaption != "")
				iw += mSize.y * 0.15f;
			nvg.fillColor(mColor);
			algn.left = true;
			algn.middle = true;
			nvg.textAlign(algn);
			
			iconPos.x = mPos.x;
			nvg.text(iconPos.x, iconPos.y, mCollapsed ? iconCollapsed[] : iconUncollapsed[]);
		}
	}

	/// The callback that is called when any type of mouse button event is issued to this Button.
	override bool mouseButtonEvent(Vector2i p, MouseButton button, bool down, int modifiers)
	{
		Widget.mouseButtonEvent(p, button, down, modifiers);

		if (button == MouseButton.Left && mEnabled)
		{
			if (down && p.y < mPos.y + fontSize)
			{
				mCollapsed = !mCollapsed;
				mUpdateLayout = true;
			}

			return true;
		}
		return false;
	}

protected:
	import nanogui.entypo : ENTYPO_ICON_CHEVRON_THIN_RIGHT, ENTYPO_ICON_CHEVRON_THIN_DOWN;
	const static dchar[1] iconCollapsed = [ENTYPO_ICON_CHEVRON_THIN_RIGHT];
	const static dchar[1] iconUncollapsed = [ENTYPO_ICON_CHEVRON_THIN_DOWN];
	string mCaption;
	string mFont;
	Color mColor;
	bool mCollapsed;
    bool mUpdateLayout;

	string[] mItems;
}
