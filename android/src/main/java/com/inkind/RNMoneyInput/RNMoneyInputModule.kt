package com.inkind.RNMoneyInput

import android.text.Editable
import android.text.TextWatcher
import android.util.Log
import android.view.MotionEvent
import android.view.View
import android.view.View.OnFocusChangeListener
import android.widget.EditText
import com.facebook.react.bridge.*
import com.facebook.react.uimanager.UIManagerModule
import java.lang.ref.WeakReference
import java.text.DecimalFormatSymbols
import java.text.NumberFormat
import java.util.*
import kotlin.math.max
import kotlin.math.min
import kotlin.math.pow

fun ReadableMap.string(key: String): String? = this.getString(key)
class RNMoneyInputModule(private val context: ReactApplicationContext) : ReactContextBaseJavaModule(context) {
    override fun getName() = "RNMoneyInput"

    @ReactMethod(isBlockingSynchronousMethod = true)
    fun formatMoney(value: Double, locale: String?): String {
        return MoneyMask.mask(value, locale)
    }

    @ReactMethod(isBlockingSynchronousMethod = true)
    fun extractValue(label: String, locale: String?): Double {
        return MoneyMask.unmask(label, locale)
    }

    @ReactMethod
    fun initializeMoneyInput(tag: Int, options: ReadableMap) {
        // We need to use prependUIBlock instead of addUIBlock since subsequent UI operations in
        // the queue might be removing the view we're looking to update.
        context.getNativeModule(UIManagerModule::class.java)!!.prependUIBlock { nativeViewHierarchyManager ->
            // The view needs to be resolved before running on the UI thread because there's a delay before the UI queue can pick up the runnable.
            val editText = nativeViewHierarchyManager.resolveView(tag) as EditText
            context.runOnUiQueueThread {
                MoneyTextListener.install(
                    field = editText,
                        locale = options.getString("locale")
                )
            }
        }
    }
}

internal class MoneyTextListener(
    field: EditText,
    locale: String?,
    private val focusChangeListener: OnFocusChangeListener
) : MoneyTextWatcher(
    field = field, locale = locale
) {
    private var previousText: String? = null
    override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {
        previousText = s?.toString()
        super.beforeTextChanged(s, start, count, after)
    }

    override fun onTextChanged(text: CharSequence, cursorPosition: Int, before: Int, count: Int) {
        val newText = text.substring(cursorPosition, cursorPosition + count)
        val oldText = previousText?.substring(cursorPosition, cursorPosition + before)
        super.onTextChanged(text, cursorPosition, before, count)
    }

    override fun onFocusChange(view: View?, hasFocus: Boolean) {
        super.onFocusChange(view, hasFocus)
        focusChangeListener.onFocusChange(view, hasFocus)
    }

    companion object {
        private const val TEXT_CHANGE_LISTENER_TAG_KEY = 123456789
        fun install(
            field: EditText,
            locale: String?,
        ) {
            if (field.getTag(TEXT_CHANGE_LISTENER_TAG_KEY) != null) {
                field.removeTextChangedListener(field.getTag(TEXT_CHANGE_LISTENER_TAG_KEY) as TextWatcher)
            }
            val listener: MoneyTextWatcher = MoneyTextListener(
                field = field, locale = locale,
                focusChangeListener = field.onFocusChangeListener
            )
            field.addTextChangedListener(listener)
            field.setOnTouchListener(listener)
            field.setOnFocusChangeListener(listener)
            field.setTag(TEXT_CHANGE_LISTENER_TAG_KEY, listener)
        }
    }
}

open class MoneyMask {
     companion object {
         val defaultLocale = "${Locale.getDefault().displayLanguage}_${Locale.getDefault().country}"

         fun getLocale(identifier: String?): Locale? {
             val localeParts = identifier?.split('_')
             val language = localeParts?.get(0) ?: "en"
             val country = localeParts?.get(1)
             return Locale(language, country)
         }

         fun getFormatter(localeIdentifer: String?): NumberFormat {
             val locale = getLocale(localeIdentifer)
             val format: NumberFormat = NumberFormat.getCurrencyInstance(locale)
             return format
         }

         fun unmask(text: String, locale: String?): Double {
             val re = "[^0-9]".toRegex()
             val numbers = re.replace(text, "")
             if (numbers.isNotEmpty()) {
                 val value = numbers.toDouble()
                 val formatter = getFormatter(locale)
                 if (formatter.maximumFractionDigits > 0) {
                     val degrees = formatter.maximumFractionDigits.toDouble()
                     return (value/ 10.0.pow(degrees))
                 }

                 return value
             }

             return 0.0
         }

         fun mask(value: Double, locale: String?): String {
             val format = getFormatter(locale)
             return format.format(value)
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
        var locale: String?,
        var listener: TextWatcher? = null
) : TextWatcher, View.OnFocusChangeListener, View.OnTouchListener {

    private var afterText: String = ""
    private var caretPosition: Int = 0

    private val field: WeakReference<EditText> = WeakReference(field)

    override fun afterTextChanged(edit: Editable?) {
        this.field.get()?.removeTextChangedListener(this)
        edit?.replace(0, edit.length, this.afterText)

        try {
            this.field.get()?.setSelection(this.caretPosition)
        } catch (e: IndexOutOfBoundsException) {
//            Log.e(
//                    "money-input-android",
//                    """
//                    WARNING! Your text field is not configured as a money field.
//                    """
//            )
        }

        this.field.get()?.addTextChangedListener(this)
        this.listener?.afterTextChanged(edit)
    }

    override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {
        this.listener?.beforeTextChanged(s, start, count, after)
    }

    override fun onTextChanged(text: CharSequence, cursorPosition: Int, before: Int, count: Int) {
        val inputText = text.toString()
        val inputCents = MoneyMask.unmask(inputText, locale)
        val maskedText = MoneyMask.mask(inputCents, locale)
        val isSuffixSymbol = maskedText.last().isDigit() == false
        this.caretPosition = maskedText.length + 1

        // Create reference to end of number section of string
        val endOfInput = if (isSuffixSymbol) maskedText.length - 2 else maskedText.length + 1

        // Is the cursor on leading edge of numbers?
        val isLeadingEdge = if (isSuffixSymbol) cursorPosition >= inputText.length - 3 else cursorPosition >= inputText.length - 1

        // Was this a deletion or middle insertion?
        val isDeletion = count == 0
        val isInsert = inputText.length > 3 && !isDeletion && !isLeadingEdge

        // Update the displayed text
        this.afterText = maskedText

        // Adjust the cursor so that it doesn't get lost in the formatting
        if (inputCents <= 0) {
            this.caretPosition = endOfInput
        }

        // Was a digit deleted or inserted at the end?
        else if (isLeadingEdge) {
            this.caretPosition = endOfInput
        }

        // Was a digit deleted in the middle?
        else if (isDeletion) {
            this.caretPosition = cursorPosition
        }

        // Was a digit inserted somewhere in the middle
        else if (isInsert) {
            this.caretPosition = endOfInput
        }

        // IDK just go the end...
        else {
            this.caretPosition = endOfInput
        }

        // Apply any offsets caused by new commas to the left of the cursor
        if (this.caretPosition > 0) {
            val symbols = DecimalFormatSymbols(MoneyMask.getLocale(locale))
            val commasAfter = maskedText.take(this.caretPosition - 1).filter{it == symbols.groupingSeparator}.length
            val commasBefore = inputText.take(this.caretPosition - 1).filter{it == symbols.groupingSeparator}.length
            val offset = commasAfter - commasBefore
            if (offset > 0 || !isLeadingEdge) {
                this.caretPosition += offset
            }
        }

        // Apply caret max
        this.caretPosition = min(this.caretPosition, endOfInput)
    }

    fun tidyCaretPosition() {
        try {
            val content = field.get()?.text.toString()
            if (content.isEmpty()) {
                val isSuffixSymbol = content.last().isDigit() == false
                if (isSuffixSymbol) {
                    this.caretPosition = min(this.caretPosition,content.length - 1)
                } else {
                    this.caretPosition = content.length
                }
            }

            if (this.caretPosition <= content.length) {
                this.field.get()?.setSelection(this.caretPosition)
            }
        } catch(err: Error) {}
    }

    override fun onFocusChange(view: View?, hasFocus: Boolean) {
        if (hasFocus) {
            tidyCaretPosition()
        }
    }

    override fun onTouch(v: View?, event: MotionEvent?): Boolean {
        tidyCaretPosition()
        return false
    }

    companion object {
        fun installOn(
                editText: EditText,
                locale: String? = null,
                listener: TextWatcher? = null,
        ): MoneyTextWatcher {
            val maskedListener = MoneyTextWatcher(
                    editText,
                    locale
            )
            editText.addTextChangedListener(maskedListener)
            editText.onFocusChangeListener = maskedListener
            return maskedListener
        }
    }
}
