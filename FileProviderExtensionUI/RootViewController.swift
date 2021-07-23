//
//  RootViewController.swift
//  FileProviderExtensionUI
//
//  Created by Philipp Schmid on 29.06.21.
//  Copyright © 2021 Skymatic GmbH. All rights reserved.
//

import CocoaLumberjackSwift
import CryptomatorCommonCore
import FileProviderUI
import UIKit
class RootViewController: FPUIActionExtensionViewController {
	private var coordinator: FileProviderCoordinator?

	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(extensionHostDidEnterBackground),
		                                       name: NSNotification.Name.NSExtensionHostDidEnterBackground,
		                                       object: nil)
	}

	@available(*, unavailable)
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	/**
	 To prevent a visible dismiss of the `RootViewController` when the FileProviderExtensionUI was in the background and becomes active again, we cancel the request as soon as the host app (Files app) switches to the background.
	 */
	@objc func extensionHostDidEnterBackground() {
		cancel()
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		let navigationController = UINavigationController()
		navigationController.navigationBar.barTintColor = UIColor(named: "primary")
		navigationController.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
		navigationController.navigationBar.tintColor = .white
		addChild(navigationController)
		view.addSubview(navigationController.view)
		navigationController.didMove(toParent: self)
		RootViewController.oneTimeSetup()
		coordinator = FileProviderCoordinator(extensionContext: extensionContext, navigationController: navigationController)
	}

	override func prepare(forError error: Error) {
		coordinator?.startWith(error: error)
	}

	@objc func cancel() {
		extensionContext.cancelRequest(withError: NSError(domain: FPUIErrorDomain, code: Int(FPUIExtensionErrorCode.userCancelled.rawValue), userInfo: nil))
	}

	static var oneTimeSetup: () -> Void = {
		// Set up logger
		LoggerSetup.oneTimeSetup()
		// Set up database
		guard let dbURL = CryptomatorDatabase.sharedDBURL else {
			// MARK: Handle error

			DDLogError("dbURL is nil")
			return {}
		}
		do {
			let dbPool = try CryptomatorDatabase.openSharedDatabase(at: dbURL)
			CryptomatorDatabase.shared = try CryptomatorDatabase(dbPool)
		} catch {
			// MARK: Handle error

			DDLogError("Error while initializing the CryptomatorDatabase: \(error)")
			return {}
		}
		return {}
	}()
}
