package expo.modules.visionimagescanner

import android.content.Context
import android.graphics.Color
import android.view.Gravity
import android.widget.TextView
import expo.modules.kotlin.AppContext
import expo.modules.kotlin.viewevent.EventDispatcher
import expo.modules.kotlin.views.ExpoView

class ExpoVisionImageScannerView(context: Context, appContext: AppContext) : ExpoView(context, appContext) {
  // Creates and initializes an event dispatcher for the `onLoad` event.
  // The name of the event is inferred from the value and needs to match the event name defined in the module.
  private val onLoad by EventDispatcher()

  // Defines a TextView that will display "Coming Soon" in black text.
  internal val textView = TextView(context).apply {
    layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT)
    text = "Coming Soon"
    textSize = 24f
    setTextColor(Color.WHITE)
    gravity = Gravity.CENTER
  }

  init {
    // Adds the TextView to the view hierarchy.
    addView(textView)
    // Trigger the onLoad event immediately since we're not loading anything
    onLoad(mapOf("message" to "Coming Soon view loaded"))
  }
}
