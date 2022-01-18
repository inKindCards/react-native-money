<div id="top"></div>


<!-- PROJECT SHIELDS -->
<!--
*** I'm using markdown "reference style" links for readability.
*** Reference links are enclosed in brackets [ ] instead of parentheses ( ).
*** See the bottom of this document for the declaration of the reference variables
*** for contributors-url, forks-url, etc. This is an optional, concise syntax you may use.
*** https://www.markdownguide.org/basic-syntax/#reference-style-links
-->
[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]


<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/inKindCards/react-native-money">
    <img src="logo.png" alt="Logo" width="160px">
  </a>

  <h3 align="center">React Native Money</h3>
  <p align="center">
    A fully native TextInput component that allows multilingual currency input <br />with a right to left text alignment.
    <br /><br />
    <a href="https://www.npmjs.com/package/@inkindcards/react-native-money">View Library</a>
    ·
    <a href="https://github.com/inKindCards/react-native-money/issues">Report Bug</a>
    ·
    <a href="https://github.com/inKindCards/react-native-money/issues">Request Feature</a>
  </p>
</div>

## What is this?

React Native Money is a simple component library that exposes a fully native TextInput component that uses currency formatting libraries provided with Android and iOS, 
so as well as being performant it is also lightweight on your binary sizes. The component has an identitical prop signature and API to the default [TextInput](https://reactnative.dev/docs/textinput) provided
with React Native, The only difference is that the `value` prop accepts a `Number` type and `onChangeText` returns a number value and formatted string.

<br />

```
npm install @inkindcards/react-native-money
```

### iOS Installation:
Make sure to add the following to your `Podfile` before running `npx pod-install`:

```
pod 'React-RCTText', :path => '../node_modules/react-native/Libraries/Text', :modular_headers => true
```

## Manual Installation
#### iOS

1. In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
2. Go to `node_modules` ➜ `react-native-money` and add `RNMoneyInput.xcodeproj`
3. In XCode, in the project navigator, select your project. Add `libRNMoneyInput.a` to your project's `Build Phases` ➜ `Link Binary With Libraries`
4. Run your project (`Cmd+R`)

#### Android

1. Open up `android/app/src/main/java/[...]/MainActivity.java`
  - Add `import com.inkind.RNMoneyInput.RNMoneyInputPackage;` to the imports at the top of the file
  - Add `new RNMoneyInputPackage()` to the list returned by the `getPackages()` method
2. Append the following lines to `android/settings.gradle`:
  	```
  	include ':react-native-money'
  	project(':react-native-money').projectDir = new File(rootProject.projectDir, 	'../node_modules/react-native-money/android')
  	```
3. Insert the following lines inside the dependencies block in `android/app/build.gradle`:
  	```
    compile project(':react-native-money')
  	```
</details>

## Usage
You use the MoneyInput component like a normal [TextInput](https://reactnative.dev/docs/textinput) from the React Native library with the exception that you pass a number to the `value` prop.
You can also pass a locale idenitifer which is composed of the language along with the country, this in turn will change the how the currency is formatted, All possible locales can be read about here: [Currency Locale Reference](https://docs.oracle.com/cd/E23824_01/html/E26033/glset.html).

```
import {useState} from 'react'
import MoneyInput from 'react-native-money'

const App = () => {
  const [bill, setBill] = useState<number>()

  return (
    <MoneyInput 
      value={bill} 
      locale='en_US'
      placeholder='$0.00'
      onChangeText={(value: number, label: string) => {
        setBill(value)
      }}
    />
  )

}

```

## Testing

Make sure to [mock](https://jestjs.io/docs/en/manual-mocks#mocking-node-modules) the following to `jest.setup.js`:
```javascript
jest.mock('react-native-money', () => ({
    default: jest.fn(),
}))
```

## Inspiration
We'd like to express thanks to the developers of [react-native-text-input-mask](https://github.com/react-native-text-input-mask/react-native-text-input-mask) as this project started as a fork of that repo
as their approach in monkeypatching the TextInput delegate was exactly what we needed.

## Versioning

This project uses semantic versioning: MAJOR.MINOR.PATCH.
This means that releases within the same MAJOR version are always backwards compatible. For more info see [semver.org](http://semver.org/).


<p align="right">(<a href="#top">back to top</a>)</p>


<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[contributors-shield]: https://img.shields.io/github/contributors/inKindCards/react-native-money.svg?style=for-the-badge
[contributors-url]: https://github.com/inKindCards/react-native-money/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/inKindCards/react-native-money.svg?style=for-the-badge
[forks-url]: https://github.com/inKindCards/react-native-money/network/members
[stars-shield]: https://img.shields.io/github/stars/inKindCards/react-native-money.svg?style=for-the-badge
[stars-url]: https://github.com/inKindCards/react-native-money/stargazers
[issues-shield]: https://img.shields.io/github/issues/inKindCards/react-native-money.svg?style=for-the-badge
[issues-url]: https://github.com/inKindCards/react-native-money/issues
[license-shield]: https://img.shields.io/github/license/inKindCards/react-native-money.svg?style=for-the-badge
[license-url]: https://github.com/inKindCards/react-native-money/blob/master/LICENSE