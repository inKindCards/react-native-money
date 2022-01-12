package com.inkind.RNMoneyInput

import com.facebook.react.ReactPackage
import com.facebook.react.bridge.JavaScriptModule
import com.facebook.react.bridge.NativeModule
import com.facebook.react.bridge.ReactApplicationContext
import com.facebook.react.uimanager.ViewManager

class RNMoneyInputPackage : ReactPackage {
    override fun createNativeModules(reactContext: ReactApplicationContext) =
        listOf<NativeModule>(RNMoneyInputModule(reactContext))

    fun createJSModules(): List<Class<out JavaScriptModule?>> = emptyList()

    override fun createViewManagers(reactContext: ReactApplicationContext): List<ViewManager<*, *>> =
        emptyList()
}
