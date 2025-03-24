<div align="center">
	<img width="900" src="https://github.com/sindresorhus/KeyboardShortcuts/raw/main/logo-light.png#gh-light-mode-only" alt="KeyboardShortcuts">
	<img width="900" src="https://github.com/sindresorhus/KeyboardShortcuts/raw/main/logo-dark.png#gh-dark-mode-only" alt="KeyboardShortcuts">
	<br>
</div>

This package lets you add support for user-customizable global keyboard shortcuts to your macOS app in minutes. It's fully sandbox and Mac App Store compatible. And it's used in production by [Dato](https://sindresorhus.com/dato), [Jiffy](https://sindresorhus.com/jiffy), [Plash](https://github.com/sindresorhus/Plash), and [Lungo](https://sindresorhus.com/lungo).

I'm happy to accept more configurability and features. PR welcome! What you see here is just what I needed for my own apps.

<img src="https://github.com/sindresorhus/KeyboardShortcuts/raw/main/screenshot.png" width="532">

## Requirements

macOS 10.15+

## Install

Add `https://github.com/sindresorhus/KeyboardShortcuts` in the [“Swift Package Manager” tab in Xcode](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app).

## Usage

First, register a name for the keyboard shortcut.

`Constants.swift`

```swift
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
	static let toggleUnicornMode = Self("toggleUnicornMode")
}
```

You can then refer to this strongly-typed name in other places.

You will want to make a view where the user can choose a keyboard shortcut.

`SettingsScreen.swift`

```swift
import SwiftUI
import KeyboardShortcuts

struct SettingsScreen: View {
	var body: some View {
		Form {
			KeyboardShortcuts.Recorder("Toggle Unicorn Mode:", name: .toggleUnicornMode)
		}
	}
}
```

*There's also [support for Cocoa](#cocoa) instead of SwiftUI.*

`KeyboardShortcuts.Recorder` takes care of storing the keyboard shortcut in `UserDefaults` and also warning the user if the chosen keyboard shortcut is already used by the system or the app's main menu.

Add a listener for when the user presses their chosen keyboard shortcut.

`App.swift`

```swift
import SwiftUI
import KeyboardShortcuts

@main
struct YourApp: App {
	@State private var appState = AppState()

	var body: some Scene {
		WindowGroup {
			// …
		}
		Settings {
			SettingsScreen()
		}
	}
}

@MainActor
@Observable
final class AppState {
	init() {
		KeyboardShortcuts.onKeyUp(for: .toggleUnicornMode) { [self] in
			isUnicornMode.toggle()
		}
	}
}
```

*You can also listen to key down with `.onKeyDown()`*

**That's all! ✨**

You can find a complete example in the “Example” directory.

You can also find a [real-world example](https://github.com/sindresorhus/Plash/blob/b348a62645a873abba8dc11ff0fb8fe423419411/Plash/PreferencesView.swift#L121-L130) in my Plash app.

#### Cocoa

Using [`KeyboardShortcuts.RecorderCocoa`](Sources/KeyboardShortcuts/RecorderCocoa.swift) instead of `KeyboardShortcuts.Recorder`:

```swift
import AppKit
import KeyboardShortcuts

final class SettingsViewController: NSViewController {
	override func loadView() {
		view = NSView()

		let recorder = KeyboardShortcuts.RecorderCocoa(for: .toggleUnicornMode)
		view.addSubview(recorder)
	}
}
```

## Localization

This package supports [localizations](/Sources/KeyboardShortcuts/Localization). PR welcome for more!

1. Fork the repo.
2. Create a directory that has a name that uses an [ISO 639-1](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) language code and optional designators, followed by the `.lproj` suffix. [More here.](https://developer.apple.com/documentation/swift_packages/localizing_package_resources)
3. Create a file named `Localizable.strings` under the new language directory and then copy the contents of `KeyboardShortcuts/Localization/en.lproj/Localizable.strings` to the new file that you just created.
4. Localize and make sure to review your localization multiple times. Check for typos.
5. Try to find someone that speaks your language to review the translation.
6. Submit a PR.

## API

[See the API docs.](https://swiftpackageindex.com/sindresorhus/KeyboardShortcuts/documentation/keyboardshortcuts/keyboardshortcuts)

## Tips

#### Show a recorded keyboard shortcut in an `NSMenuItem`

<!-- TODO: Link to the docs instead when DocC supports showing type extensions. -->

See [`NSMenuItem#setShortcut`](https://github.com/sindresorhus/KeyboardShortcuts/blob/0dcedd56994d871f243f3d9c76590bfd9f8aba69/Sources/KeyboardShortcuts/NSMenuItem%2B%2B.swift#L14-L41).

#### Dynamic keyboard shortcuts

Your app might need to support keyboard shortcuts for user-defined actions. Normally, you would statically register the keyboard shortcuts upfront in `extension KeyboardShortcuts.Name {}`. However, this is not a requirement. It's only for convenience so that you can use dot-syntax when calling various APIs (for example, `.onKeyDown(.unicornMode) {}`). You can create `KeyboardShortcut.Name`'s dynamically and store them yourself. You can see this in action in the example project.

#### Default keyboard shortcuts

Setting a default keyboard shortcut can be useful if you're migrating from a different package or just making something for yourself. However, please do not set this for a publicly distributed app. Users find it annoying when random apps steal their existing keyboard shortcuts. It’s generally better to show a welcome screen on the first app launch that lets the user set the shortcut.

```swift
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
	static let toggleUnicornMode = Self("toggleUnicornMode", default: .init(.k, modifiers: [.command, .option]))
}
```

#### Get all keyboard shortcuts

To get all the keyboard shortcut `Name`'s, conform `KeyboardShortcuts.Name` to `CaseIterable`.

```swift
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
	static let foo = Self("foo")
	static let bar = Self("bar")
}

extension KeyboardShortcuts.Name: CaseIterable {
	public static let allCases: [Self] = [
		.foo,
		.bar
	]
}

// …

print(KeyboardShortcuts.Name.allCases)
```

And to get all the `Name`'s with a set keyboard shortcut:

```swift
print(KeyboardShortcuts.Name.allCases.filter { $0.shortcut != nil })
```

## FAQ

#### How is it different from [`MASShortcut`](https://github.com/shpakovski/MASShortcut)?

This package:
- Written in Swift with a swifty API.
- More native-looking UI component.
- SwiftUI component included.
- Support for listening to key down, not just key up.
- Swift Package Manager support.
- Connect a shortcut to an `NSMenuItem`.
- Works when [`NSMenu` is open](https://github.com/sindresorhus/KeyboardShortcuts/issues/1) (e.g. menu bar apps).

`MASShortcut`:
- More mature.
- More localizations.

#### How is it different from [`HotKey`](https://github.com/soffes/HotKey)?

`HotKey` is good for adding hard-coded keyboard shortcuts, but it doesn't provide any UI component for the user to choose their own keyboard shortcuts.

#### Why is this package importing `Carbon`? Isn't that deprecated?

Most of the Carbon APIs were deprecated years ago, but there are some left that Apple never shipped modern replacements for. This includes registering global keyboard shortcuts. However, you should not need to worry about this. Apple will for sure ship new APIs before deprecating the Carbon APIs used here.

#### Does this package cause any permission dialogs?

No.

#### How can I add an app-specific keyboard shortcut that is only active when the app is?

That is outside the scope of this package. You can either use [`NSEvent.addLocalMonitorForEvents`](https://developer.apple.com/documentation/appkit/nsevent/1534971-addlocalmonitorforevents), [`NSMenuItem` with keyboard shortcut](https://developer.apple.com/documentation/appkit/nsmenuitem/2880316-allowskeyequivalentwhenhidden) (it can even be hidden), or SwiftUI's [`View#keyboardShortcut()` modifier](https://developer.apple.com/documentation/swiftui/form/keyboardshortcut(_:)).

#### Does it support media keys?

No, since it would not work for sandboxed apps. If your app is not sandboxed, you can use [`MediaKeyTap`](https://github.com/nhurden/MediaKeyTap).

#### Can you support CocoaPods or Carthage?

No. However, there is nothing stopping you from using Swift Package Manager for just this package even if you normally use CocoaPods or Carthage.

## Related

- [Defaults](https://github.com/sindresorhus/Defaults) - Swifty and modern UserDefaults
- [LaunchAtLogin](https://github.com/sindresorhus/LaunchAtLogin) - Add "Launch at Login" functionality to your macOS app
- [More…](https://github.com/search?q=user%3Asindresorhus+language%3Aswift+archived%3Afalse&type=repositories)

## Example

```swift
import SwiftUI

@MainActor
final class CallbackMenuItem: NSMenuItem {
	private static var validateCallback: ((NSMenuItem) -> Bool)?

	static func validate(_ callback: @escaping (NSMenuItem) -> Bool) {
		validateCallback = callback
	}

	private let callback: () -> Void

	init(
		_ title: String,
		key: String = "",
		keyModifiers: NSEvent.ModifierFlags? = nil,
		isEnabled: Bool = true,
		isChecked: Bool = false,
		isHidden: Bool = false,
		action: @escaping () -> Void
	) {
		self.callback = action
		super.init(title: title, action: #selector(action(_:)), keyEquivalent: key)
		self.target = self
		self.isEnabled = isEnabled
		self.isChecked = isChecked
		self.isHidden = isHidden

		if let keyModifiers {
			self.keyEquivalentModifierMask = keyModifiers
		}
	}

	@available(*, unavailable)
	required init(coder decoder: NSCoder) {
		// swiftlint:disable:next fatal_error_message
		fatalError()
	}

	@objc
	private func action(_ sender: NSMenuItem) {
		callback()
	}
}

extension CallbackMenuItem: NSMenuItemValidation {
	func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
		Self.validateCallback?(menuItem) ?? true
	}
}

extension NSMenuItem {
	convenience init(
		_ title: String,
		action: Selector? = nil,
		key: String = "",
		keyModifiers: NSEvent.ModifierFlags? = nil,
		data: Any? = nil,
		isEnabled: Bool = true,
		isChecked: Bool = false,
		isHidden: Bool = false
	) {
		self.init(title: title, action: action, keyEquivalent: key)
		self.representedObject = data
		self.isEnabled = isEnabled
		self.isChecked = isChecked
		self.isHidden = isHidden

		if let keyModifiers {
			self.keyEquivalentModifierMask = keyModifiers
		}
	}

	var isChecked: Bool {
		get { state == .on }
		set {
			state = newValue ? .on : .off
		}
	}
}

extension NSMenu {
	@MainActor
	@discardableResult
	func addCallbackItem(
		_ title: String,
		key: String = "",
		keyModifiers: NSEvent.ModifierFlags? = nil,
		isEnabled: Bool = true,
		isChecked: Bool = false,
		isHidden: Bool = false,
		action: @escaping () -> Void
	) -> NSMenuItem {
		let menuItem = CallbackMenuItem(
			title,
			key: key,
			keyModifiers: keyModifiers,
			isEnabled: isEnabled,
			isChecked: isChecked,
			isHidden: isHidden,
			action: action
		)
		addItem(menuItem)
		return menuItem
	}
}
```
```swift
import SwiftUI
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
	static let testShortcut1 = Self("testShortcut1")
	static let testShortcut2 = Self("testShortcut2")
	static let testShortcut3 = Self("testShortcut3")
	static let testShortcut4 = Self("testShortcut4")
}

private struct DynamicShortcutRecorder: View {
	@FocusState private var isFocused: Bool

	@Binding var name: KeyboardShortcuts.Name
	@Binding var isPressed: Bool

	var body: some View {
		HStack(alignment: .firstTextBaseline) {
			KeyboardShortcuts.Recorder(for: name)
				.focused($isFocused)
				.padding(.trailing, 10)
			Text("Pressed? \(isPressed ? "👍" : "👎")")
				.frame(width: 100, alignment: .leading)
		}
		.onChange(of: name) {
			isFocused = true
		}
	}
}

private struct DynamicShortcut: View {
	private struct Shortcut: Hashable, Identifiable {
		var id: String
		var name: KeyboardShortcuts.Name
	}

	private static let shortcuts = [
		Shortcut(id: "Shortcut3", name: .testShortcut3),
		Shortcut(id: "Shortcut4", name: .testShortcut4)
	]

	@State private var shortcut = Self.shortcuts.first!
	@State private var isPressed = false

	var body: some View {
		VStack {
			Text("Dynamic Recorder")
				.bold()
				.padding(.bottom, 10)
			VStack {
				Picker("Select shortcut:", selection: $shortcut) {
					ForEach(Self.shortcuts) {
						Text($0.id)
							.tag($0)
					}
				}
				Divider()
				DynamicShortcutRecorder(name: $shortcut.name, isPressed: $isPressed)
			}
			Divider()
				.padding(.vertical)
			Button("Reset All") {
				KeyboardShortcuts.resetAll()
			}
		}
		.frame(maxWidth: 300)
		.padding()
		.padding(.bottom, 20)
		.onChange(of: shortcut, initial: true) { oldValue, newValue in
			onShortcutChange(oldValue: oldValue, newValue: newValue)
		}
	}

	private func onShortcutChange(oldValue: Shortcut, newValue: Shortcut) {
		KeyboardShortcuts.disable(oldValue.name)

		KeyboardShortcuts.onKeyDown(for: newValue.name) {
			isPressed = true
		}

		KeyboardShortcuts.onKeyUp(for: newValue.name) {
			isPressed = false
		}
	}
}

private struct DoubleShortcut: View {
	@State private var isPressed1 = false
	@State private var isPressed2 = false

	var body: some View {
		Form {
			KeyboardShortcuts.Recorder("Shortcut 1:", name: .testShortcut1)
				.overlay(alignment: .trailing) {
					Text("Pressed? \(isPressed1 ? "👍" : "👎")")
						.offset(x: 90)
				}
			KeyboardShortcuts.Recorder(for: .testShortcut2) {
				Text("Shortcut 2:") // Intentionally using the verbose initializer for testing.
			}
			.overlay(alignment: .trailing) {
				Text("Pressed? \(isPressed2 ? "👍" : "👎")")
					.offset(x: 90)
			}
			Spacer()
		}
		.offset(x: -40)
		.frame(maxWidth: 300)
		.padding()
		.padding()
		.onGlobalKeyboardShortcut(.testShortcut1) {
			isPressed1 = $0 == .keyDown
		}
		.onGlobalKeyboardShortcut(.testShortcut2, type: .keyDown) {
			isPressed2 = true
		}
		.task {
			KeyboardShortcuts.onKeyUp(for: .testShortcut2) {
				isPressed2 = false
			}
		}
	}
}

struct MainScreen: View {
	var body: some View {
		VStack {
			DoubleShortcut()
			Divider()
			DynamicShortcut()
		}
		.frame(width: 400, height: 320)
	}
}

#Preview {
	MainScreen()
}
```

```
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>com.apple.security.app-sandbox</key>
	<true/>
</dict>
</plist>
```

```
import SwiftUI

@MainActor
final class AppState {
	static let shared = AppState()

	private init() {}

	func createMenus() {
		let testMenuItem = NSMenuItem()
		NSApp.mainMenu?.addItem(testMenuItem)

		let testMenu = NSMenu()
		testMenu.title = "Test"
		testMenuItem.submenu = testMenu

		testMenu.addCallbackItem("Shortcut 1") { [weak self] in
			self?.alert(1)
		}
		.setShortcut(for: .testShortcut1)

		testMenu.addCallbackItem("Shortcut 2") { [weak self] in
			self?.alert(2)
		}
		.setShortcut(for: .testShortcut2)

		testMenu.addCallbackItem("Shortcut 3") { [weak self] in
			self?.alert(3)
		}
		.setShortcut(for: .testShortcut3)

		testMenu.addCallbackItem("Shortcut 4") { [weak self] in
			self?.alert(4)
		}
		.setShortcut(for: .testShortcut4)
	}

	private func alert(_ number: Int) {
		let alert = NSAlert()
		alert.messageText = "Shortcut \(number) menu item action triggered!"
		alert.runModal()
	}
}
```

```
import SwiftUI

@main
struct AppMain: App {
	var body: some Scene {
		WindowGroup {
			MainScreen()
				.task {
					AppState.shared.createMenus()
				}
		}
	}
}
```