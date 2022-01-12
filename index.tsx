import React, {
  forwardRef,
  useEffect,
  useImperativeHandle,
  useRef,
  useState,
} from 'react'

import {
  findNodeHandle,
  NativeModules,
  TextInput,
  TextInputProps,
} from 'react-native'

const {RNMoneyInput} = NativeModules as {RNMoneyInput: MaskOperations}

if (!RNMoneyInput) {
  throw new Error(`NativeModule: RNMoneyInput is null.
To fix this issue try these steps:
  • Rebuild and restart the app.
  • Run the packager with \`--clearCache\` flag.
  • If happening on iOS, run \`pod install\` in the \`ios\` directory and then rebuild and re-run the app.
`)
}

type MaskOperations = {
  setMask: (reactNode: Number, options: any) => void
  formatMoney: (value: Number, locale?: string) => string
  extractValue: (label: string) => number
}

type MoneyInputProps = TextInputProps & {
  locale?: string
  onChangeText?: (value: number, label: string) => void
}

interface Handles {
  focus: () => void
  blur: () => void
}

const MoneyInput = forwardRef<Handles, MoneyInputProps>(
  ({defaultValue, value, onChangeText, locale, ...rest}, ref) => {
    // Keep a reference to the actual text input
    const input = useRef<TextInput>(null)
    const [label, setLabel] = useState<string>()

    // Convert TextInput to MoneyInput native type
    useEffect(() => {
      const nodeId = findNodeHandle(input.current)
      if (nodeId) RNMoneyInput.setMask(nodeId, { locale })
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
        onChangeText={async label => {
          setLabel(label)
          onChangeText?.(RNMoneyInput.extractValue(label), label)
        }}
      />
    )
  }
)

export default MoneyInput
