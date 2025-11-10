import React, {
  forwardRef,
  useEffect,
  useImperativeHandle,
  useRef,
  useState,
} from 'react'

import {TextInput, TextInputProps, findNodeHandle, NativeModules} from 'react-native'

// Import TurboModule spec
import NativeMoneyInput from './src/NativeMoneyInput'

// Fallback to legacy NativeModules if TurboModule not available
const RNMoneyInput = NativeMoneyInput ?? NativeModules.RNMoneyInput

if (!RNMoneyInput) {
  throw new Error(`NativeModule: RNMoneyInput is null.
To fix this issue try these steps:
  • Rebuild and restart the app.
  • Run the packager with \`--clearCache\` flag.
  • If happening on iOS, run \`pod install\` in the \`ios\` directory and then rebuild and re-run the app.
`)
}

export const {initializeMoneyInput, extractValue, formatMoney} = RNMoneyInput

type MoneyInputProps = TextInputProps & {
  value?: number
  defaultValue?: number
  locale?: string
  onChangeText?: (value: number, label: string) => void
}

interface Handles {
  focus: () => void
  blur: () => void
}

const MoneyInput = forwardRef<Handles, MoneyInputProps>(
  ({defaultValue, value, onChangeText, locale, onFocus, ...rest}, ref) => {
    // Create a default input
    const [defaultMoney] = useState(defaultValue ?? value)
    const [defaultLabel] = useState(
      defaultMoney != null ? formatMoney(defaultMoney, locale) : ''
    )

    // Keep a reference to the actual text input
    const input = useRef<TextInput>(null)
    const [rawValue, setValue] = useState<number | undefined>(defaultMoney)
    const [label, setLabel] = useState<string>(defaultLabel)

    // Keep numeric prop in sync with out state
    useEffect(() => {
      if (value != null && value != rawValue) {
        setValue(value)
        setLabel(formatMoney(value, locale))
      }
    }, [value, rawValue])

    // Convert TextInput to MoneyInput native type
    useEffect(() => {
      const timer = setTimeout(() => {
        if (!input.current) {
          console.warn('MoneyInput: input ref is null')
          return
        }

        let nodeId = null

        try {
          // Try multiple methods to get the node handle
          // Method 1: findNodeHandle (works in both architectures but deprecated)
          nodeId = findNodeHandle(input.current)

          if (!nodeId) {
            // Method 2: Direct _nativeTag access (new arch)
            // @ts-ignore
            nodeId = input.current._nativeTag
          }

          if (nodeId) {
            console.log('MoneyInput: Initializing with nodeId:', nodeId)
            initializeMoneyInput(nodeId, {locale})
          } else {
            console.warn('MoneyInput: Could not get node handle')
          }
        } catch (e) {
          console.error('MoneyInput: Error getting node handle:', e)
        }
      }, 100) // Small delay to ensure ref is mounted

      return () => clearTimeout(timer)
    }, [locale])

    // Create a false ref interface
    useImperativeHandle(ref, () => ({
      focus: () => {
        input.current?.focus()
      },
      blur: () => {
        input.current?.blur()
      },
    }))

    return (
      <TextInput
        {...rest}
        ref={input}
        value={label}
        onFocus={e => {
          if (defaultLabel == '' && !rawValue) {
            setValue(0)
            setLabel(formatMoney(0, locale))
          }

          onFocus?.(e)
        }}
        onChangeText={async label => {
          console.log('Got Label:', label)
          const computedValue = extractValue(label, locale)
          setLabel(label)
          setValue(computedValue)
          onChangeText?.(computedValue, label)
        }}
      />
    )
  }
)

export default MoneyInput
