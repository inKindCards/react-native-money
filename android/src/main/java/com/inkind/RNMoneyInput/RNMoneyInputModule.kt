package com.inkind.RNMoneyInput

import android.text.Editable
import android.text.TextWatcher
import android.util.Log
import android.view.View
import android.view.View.OnFocusChangeListener
import android.widget.EditText
import com.facebook.react.bridge.*
import com.facebook.react.uimanager.UIManagerModule
import java.lang.ref.WeakReference
import java.text.NumberFormat
import java.util.*

fun ReadableMap.string(key: String): String? = this.getString(key)
class RNMoneyInputModule(private val context: ReactApplicationContext) : ReactContextBaseJavaModule(context) {
    override fun getName() = "RNMoneyInput"

    @ReactMethod
    fun setMask(tag: Int) {
        // We need to use prependUIBlock instead of addUIBlock since subsequent UI operations in
        // the queue might be removing the view we're looking to update.
        context.getNativeModule(UIManagerModule::class.java)!!.prependUIBlock { nativeViewHierarchyManager ->
            // The view needs to be resolved before running on the UI thread because there's a delay before the UI queue can pick up the runnable.
            val editText = nativeViewHierarchyManager.resolveView(tag) as EditText
            context.runOnUiQueueThread {
                MoneyTextListener.install(
                    field = editText
                )
            }
        }
    }
}

internal class MoneyTextListener(
    field: EditText,
    private val focusChangeListener: OnFocusChangeListener
) : MoneyTextWatcher(
    field = field,
) {
    private var previousText: String? = null
    override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {
        previousText = s?.toString()
        super.beforeTextChanged(s, start, count, after)
    }

    override fun onTextChanged(text: CharSequence, cursorPosition: Int, before: Int, count: Int) {
        val newText = text.substring(cursorPosition, cursorPosition + count)
        val oldText = previousText?.substring(cursorPosition, cursorPosition + before)
        // temporarily disable autocomplete if updated text is same as previous text,
        // this is to prevent autocomplete when deleting as value is set multiple times from RN
        val isDuplicatePayload = count == before && newText == oldText
        if (isDuplicatePayload == false) {
            super.onTextChanged(text, cursorPosition, before, count)
        }
    }

    override fun onFocusChange(view: View?, hasFocus: Boolean) {
        super.onFocusChange(view, hasFocus)
        focusChangeListener.onFocusChange(view, hasFocus)
    }

    companion object {
        private const val TEXT_CHANGE_LISTENER_TAG_KEY = 123456789
        fun install(
            field: EditText,
        ) {
            if (field.getTag(TEXT_CHANGE_LISTENER_TAG_KEY) != null) {
                field.removeTextChangedListener(field.getTag(TEXT_CHANGE_LISTENER_TAG_KEY) as TextWatcher)
            }
            val listener: MoneyTextWatcher = MoneyTextListener(
                field = field,
                focusChangeListener = field.onFocusChangeListener
            )
            field.addTextChangedListener(listener)
            field.onFocusChangeListener = listener
            field.setTag(TEXT_CHANGE_LISTENER_TAG_KEY, listener)
        }
    }
}

/**
 * TextWatcher implementation.
 *
 * TextWatcher implementation, which applies masking to the user input, picking the most suitable mask for the text.
 *
 * Might be used as a decorator, which forwards TextWatcher calls to its own listener.
 */
open class MoneyTextWatcher(
        field: EditText,
        var listener: TextWatcher? = null
) : TextWatcher, View.OnFocusChangeListener {

    private var afterText: String = ""
    private var caretPosition: Int = 0

    private val field: WeakReference<EditText> = WeakReference(field)

    /**
     * Convenience constructor.
     */
    constructor(field: EditText):
            this(field, null)


    override fun afterTextChanged(edit: Editable?) {
        this.field.get()?.removeTextChangedListener(this)
        edit?.replace(0, edit.length, this.afterText)

        try {
            this.field.get()?.setSelection(this.caretPosition)
        } catch (e: IndexOutOfBoundsException) {
            Log.e(
                    "money-input-android",
                    """
                    WARNING! Your text field is not configured as a money field. 
                    """
            )
        }

        this.field.get()?.addTextChangedListener(this)
        this.listener?.afterTextChanged(edit)
    }

    override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {
        this.listener?.beforeTextChanged(s, start, count, after)
    }

    fun unmask(text: String): Double {
        val re = "[^0-9]".toRegex()
        val numbers = re.replace(text, "")
        val cents = numbers.toDouble()
        return cents
    }

    fun mask(cents: Double): String {
        val dollars = cents / 100
        val format: NumberFormat = NumberFormat.getCurrencyInstance(Locale.US)
        format.maximumFractionDigits = 2
        return format.format(dollars)
    }

    override fun onTextChanged(text: CharSequence, cursorPosition: Int, before: Int, count: Int) {
        val inputText = text.toString()
        val inputCents = this.unmask(inputText)
        val maskedText = this.mask(inputCents)

        this.afterText = maskedText
        this.caretPosition = cursorPosition + maskedText.length
    }

    override fun onFocusChange(view: View?, hasFocus: Boolean) {}

    companion object {
        fun installOn(
                editText: EditText,
        ): MoneyTextWatcher = installOn(
                editText
        )

        fun installOn(
                editText: EditText,
                listener: TextWatcher? = null,
        ): MoneyTextWatcher {
            val maskedListener = MoneyTextWatcher(
                    editText
            )
            editText.addTextChangedListener(maskedListener)
            editText.onFocusChangeListener = maskedListener
            return maskedListener
        }
    }
}