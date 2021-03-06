
import UIKit
import Material
import Firebase

fileprivate let kColorNavy = UIColor(red: 23/255.0, green: 85/255.0, blue: 122/255.0, alpha: 1)

/**
 * `DiningHallViewController` displays the details of a single `DiningHall`.
 * 
 * This controller is designed to be placed within a `ResourceContainerController`, giving data as a `ResourceDetailProvider`.
 * The view only contains a tab pages of the menus, without showing any data about the `DiningHall` itself (e.g. names, times, etc).
 */
class DiningHallViewController: UIViewController, IBInitializable, ResourceDetailProvider, PageTabBarControllerDelegate
{
    var image: UIImage?
    
    var caf = false
    
    var cafe: CafeClass!
    
    private var hall: DiningHall!
    
    
    private let sortMenuController = ListMenuController()
    
    private var menuControllers: [DiningMenuViewController]!
    private var pageController: PageTabBarController!
    private var pageTabBar: PageTabBar
    {
        PageTabBar.appearance().tintColor = UIColor(hue: 0.5583, saturation: 0.79, brightness: 0.97, alpha: 1.0)
        
        return pageController.pageTabBar
        
    }
    
    private var selectedScroll: DelegatesScroll
    {
        return menuControllers[ pageController.selectedIndex ]
    }
    
    
    // ========================================
    // MARK: - IBInitializable
    // ========================================
    typealias IBComponent = DiningHallViewController
    
    static var componentID: String { return className(IBComponent.self) }
    
    static func fromIB() -> IBComponent
    {
        return UIStoryboard.dining.instantiateViewController(withIdentifier: self.componentID) as! IBComponent
    }
    
    
    // ========================================
    // MARK: - ResourceDataProvider
    // ========================================
    static func newInstance() -> ResourceDetailProvider
    {
        return fromIB()
    }
    
    var resource: Resource
    {
        get {
            if caf == true {
                return cafe
            } else {
                return hall
            }
        
        }
        set
        {
            if viewIfLoaded == nil, hall == nil, let newHall = newValue as? DiningHall
            {
                
                hall = newHall
                title = hall.name
            }
            if viewIfLoaded == nil, hall == nil, let newHall = newValue as? CafeClass
            {
                
                cafe = newHall
                caf = true
                title = cafe.name
            }
        }
    }
    
    var viewController: UIViewController { return self }
    
    // TODO: Fill real data here.
    var imageURL: URL? { return hall?.imageURL }
    var text1: String? { return nil } // address
    var text2: String? { return nil } // open status
    
    /// Buttons for the container to make available.
    var buttons: [UIButton]
    {
        let sort = IconButton(image: #imageLiteral(resourceName: "ic_sort"), tintColor: .white)
        sort.addTarget(self, action: #selector(sortTapped), for: .touchUpInside)
        return []
    }
    
    /// Content size of the current menu tab page.
    var contentSize: CGSize
    {
        let size = selectedScroll.contentSize
        return CGSize(width: size.width, height: size.height + pageTabBar.bounds.height)
    }
    
    /// Scroll for the current menu tab page not animated.
    var contentOffset: CGPoint
    {
        get { return selectedScroll.contentOffset }
        set { setContentOffset(newValue, animated: false) }
    }
    
    /// Set the scroll for the currently selected menu tab page.
    func setContentOffset(_ offset: CGPoint, animated: Bool)
    {
        selectedScroll.setContentOffset(offset, animated: false)
    }
    
    /// Whether the receiving container should reset content offset when content size is changed.
    var resetOffsetOnSizeChanged: Bool { return true }
    
    /// Callback for when the internal `contentSize` has changed.
    var contentSizeChangeHandler: ((ResourceDetailProvider) -> Void)?
    
    
    // ========================================
    // MARK: - UIViewController
    // ========================================
    
    /// Call necessary setup methods.
    override func viewDidLoad() 
    {
        super.viewDidLoad()
        PageTabBar.appearance().tintColor = UIColor(hue: 0.5583, saturation: 0.79, brightness: 0.97, alpha: 1.0)
        setupMenus()
        setupSortMenu()
    }
    
    /// Manually call the transition handler for initial page.
    override func viewWillAppear(_ animated: Bool)
    {
        
        super.viewWillAppear(animated)
        
        // TODO: open to the closest meal type.
        // TODO: restore sort preferences.
        sortMenus(by: .favorites)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if caf {
            Analytics.logEvent("opened_cafe", parameters: ["cafe" : cafe.name])
        } else {
            Analytics.logEvent("opened_dining_hall", parameters: ["dining_hall" : hall.name])
        }

    }
    // ========================================
    // MARK: - PageTabBarControllerDelegate
    // ========================================
    
    /// When the page changes, set a new scroll, and call the `contentSizeChangeHandler`.
    func pageTabBarController(pageTabBarController: PageTabBarController, didTransitionTo viewController: UIViewController)
    {
        contentSizeChangeHandler?(self)
    }
    
    
    // ========================================
    // MARK: - Private
    // ========================================
    
    /// Initialize and configure `DiningMenuViewControllers` to add as tab pages.
    private func setupMenus()
    {
        let menuID = className(DiningMenuViewController.self)
        
        var to_filter: [MealType] = []
        for type in MealType.allValues {
            
            if caf {
                let shift = cafe.meals[type]!
                if type.name.split(separator: "_")[0].lowercased() != "limited" && !shift.hours.isNil && shift.menu.count != 0{
                    to_filter.append(type)
                }
            } else {
                let shift = hall.meals[type]!
                if !shift.hours.isNil && shift.menu.count != 0 {
                    to_filter.append(type)
                }
            }
        }
        menuControllers = to_filter.map
        { type in
            
            let vc = storyboard!.instantiateViewController(withIdentifier: menuID) as! DiningMenuViewController
            
            if caf {
                vc.setData((type: type, shift: cafe.meals[type]!))
                
            } else {
                vc.setData((type: type, shift: hall.meals[type]!))
                
            }
        
            let barItem = vc.pageTabBarItem
            barItem.titleColor = kColorNavy
            barItem.pulseColor = kColorNavy//UIColor.white
            
            barItem.title = type.name.split(separator: "_")[0].capitalized
            barItem.titleLabel?.font = UIFont.systemFont(ofSize: 16)
            return vc
        }
        
        pageController = PageTabBarController(viewControllers: menuControllers, selectedIndex: 0)
        pageController.pageTabBarAlignment = .top
        pageController.delegate = self
    
        let tabBar = pageController.pageTabBar
        tabBar.tintColor = UIColor(hue: 0.5583, saturation: 0.79, brightness: 0.97, alpha: 1.0)
        tabBar.backgroundColor = UIColor.white
        tabBar.lineColor = kColorNavy
        tabBar.lineHeight = 1
        tabBar.lineAlignment = .bottom
        
        let menus = pageController.view!
        menus.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        addChildViewController(pageController)
        view.addSubview(menus)
    }
    
    /// Intialize and configure the modal `ListMenuController` for sorting options.
    private func setupSortMenu()
    {
        let menu = sortMenuController
        menu.message = "Sort by"
        menu.clearOnNewSelection = true
        
        let handler = { (item: ListMenuItem, order: FavorableSortBy) in
            
            menu.setItem(item, selected: true)
            self.sortMenus(by: order)
            
            self.dismiss(animated: true, completion: nil)
        }
        
        menu.addItem(ListMenuItem(text: "Alphabetical", icon: #imageLiteral(resourceName: "ic_sort_by_alpha"), tint: Color.blue.darken1, selected: false) { handler($0, .alphabetical) })
        menu.addItem(ListMenuItem(text: "Favorites", icon: #imageLiteral(resourceName: "ic_favorite"), tint: Color.pink.base, selected: true){ handler($0, .favorites) })
        menu.addItem(ListMenuItem(text: "Cancel", icon: #imageLiteral(resourceName: "ic_close")){ _ in self.dismiss(animated: true, completion: nil) })
    }
    
    /// Tells each `DiningMenuViewController` to sort by the given `FavorableSortBy` ordering.
    private func sortMenus(by order: FavorableSortBy)
    {
        menuControllers.forEach { $0.sortBy = order }
    }
    
    /**
     * Called when the sort button (given through `ResourceDetailProvider`) is tapped.
     * Present the menu through the parent if there is one; otherwise through itself.
     */
    func sortTapped()
    {
        let presentingVC = self.parent ?? self
        presentingVC.present(sortMenuController, animated: true, completion: nil)
    }
}
