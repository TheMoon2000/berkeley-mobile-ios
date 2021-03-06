
import UIKit


/// Get class name of obj as string.
func className(_ c: AnyClass) -> String
{
    return String(describing: c)
}

/// Globally set the status bar style/color.
func setStatusBarStyle(_ style: UIStatusBarStyle)
{
    UIApplication.shared.statusBarStyle = style
}

func logFunc(_ caller: Any, _ name: String = #function)
{
    print("\( type(of: caller) ).\(name)")
}
