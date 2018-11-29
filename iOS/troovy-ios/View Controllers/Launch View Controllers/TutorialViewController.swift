//
//  TutorialViewController.swift
//  troovy-ios
//
//  Created by Daniil on 11.08.17.
//  Copyright © 2017 ForaSoft. All rights reserved.
//

import UIKit

import EMPageViewController

class TutorialViewController: TroovyViewController, EMPageViewControllerDelegate, EMPageViewControllerDataSource {
    
    // MARK: Interface Builder Properties
    
    @IBOutlet weak var skipButton: RoundedButton!
    @IBOutlet weak var pageControl: UIPageControl!
    
    // MARK: Private Properties
    
    private var unauthorisedUserService: UnauthorisedUserService!
    
    private var pageViewController: EMPageViewController!
    private var tutorialPages: [UIViewController] = []
    private var scrollInProgress = false

    // MARK: Init Methods & Superclass Overriders
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.setupTutorialPages()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let pageViewController = segue.destination as? EMPageViewController {
            self.pageViewController = pageViewController
            self.pageViewController.delegate = self
            self.pageViewController.dataSource = self
            self.pageViewController.scrollView.isScrollEnabled = true
        }
    }
    
    override func inject(propertiesWithAssembly assembly: ViewControllerAssemblyManager) {
        self.unauthorisedUserService = assembly.unauthorisedUserService
    }
    
    // MARK: Private Methods
    
    private func setupTutorialPages() {
        if self.tutorialPages.count != 0 {
            return
        }
        
        self.pageViewController.scrollView.bounces = false
        
        let tutorialTitles = ApplicationMessages.Instructions.tutorialTitles
        let tutorialMessages = ApplicationMessages.Instructions.tutorialMessages
        for index in 0..<tutorialMessages.count {
            let tutorialTitle = tutorialTitles[index]
            let tutorialMessage = tutorialMessages[index]
            let tutorialImage = UIImage.tv_tutorialImage(withIndex: index)
            
            let tutorialPageViewController = self.storyboard?.instantiateViewController(withIdentifier: "TutorialPageViewController") as! TutorialPageViewController
            tutorialPageViewController.configure(withTitle: tutorialTitle, message: tutorialMessage, image: tutorialImage)
            
            self.tutorialPages.append(tutorialPageViewController)
        }
        
        if let firstViewController = self.tutorialPages.first {
            self.pageViewController.selectViewController(firstViewController, direction: .forward, animated: false, completion: nil)
            
        }
    }
    
    // MARK: Controls Actions
    
    @IBAction func skipButtonAction(_ sender: UIButton) {
        
        if scrollInProgress { return }
        
        scrollInProgress = true
        
        self.view.endEditing(true)
        let pcount = self.tutorialPages.count - 1
        if pageControl.currentPage >= pcount {
        
            self.unauthorisedUserService.setTutorialPassed()
            self.presentingViewController?.dismiss(animated: true, completion: { [weak self] in
                self?.scrollInProgress = false
            })
        } else if pageControl.currentPage < pcount {
            self.pageViewController.scrollForward(animated: true) { [weak self](success) in
                self?.scrollInProgress = false
            }
        }
    }
    
    // MARK: Protocols Implementation
    
    // MARK: EMPageViewControllerDelegate & EMPageViewControllerDataSource
    
    internal func em_pageViewController(_ pageViewController: EMPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        if let viewControllerIndex = self.tutorialPages.index(of: viewController) {
            let newIndex = viewControllerIndex - 1
            if newIndex >= 0 && newIndex < self.tutorialPages.count {
                let newViewController = self.tutorialPages[newIndex]
                return newViewController
            }
        }
        
        return nil
    }
    
    internal func em_pageViewController(_ pageViewController: EMPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        if let viewControllerIndex = self.tutorialPages.index(of: viewController) {
            let newIndex = viewControllerIndex + 1
            if newIndex >= 0 && newIndex < self.tutorialPages.count {
                let newViewController = self.tutorialPages[newIndex]
                return newViewController
            }
        }
        
        return nil
    }
    
    internal func em_pageViewController(_ pageViewController: EMPageViewController, didFinishScrollingFrom startingViewController: UIViewController?, destinationViewController:UIViewController, transitionSuccessful: Bool) {
        if let viewControllerIndex = self.tutorialPages.index(of: destinationViewController) {
            pageControl.currentPage = viewControllerIndex
            if pageControl.currentPage == self.tutorialPages.count - 1 {
                skipButton.setTitle(ApplicationMessages.ButtonsTitles.getStarted, for: .normal)
            } else {
                skipButton.setTitle(ApplicationMessages.ButtonsTitles.next, for: .normal)
            }
        }
    }
    
}
