//
//  WorkingSetObserverTests.swift
//  CryptomatorFileProviderTests
//
//  Created by Philipp Schmid on 25.01.22.
//  Copyright © 2022 Skymatic GmbH. All rights reserved.
//

import CryptomatorCloudAccessCore
import GRDB
import XCTest
@testable import CryptomatorFileProvider

class WorkingSetObserverTests: XCTestCase {
	var observer: WorkingSetObserver!
	var notificatorMock: FileProviderNotificatorTypeMock!
	let updatedMetadataIDs: [Int64] = [1, 2, 3]
	lazy var updatedItems: [FileProviderItem] = updatedMetadataIDs.map {
		FileProviderItem(metadata: ItemMetadata(id: $0, name: "\($0)", type: .file, size: nil, parentID: 0, lastModifiedDate: nil, statusCode: .isDownloading, cloudPath: CloudPath("/\($0)"), isPlaceholderItem: false))
	}

	override func setUpWithError() throws {
		notificatorMock = FileProviderNotificatorTypeMock()
		observer = WorkingSetObserver(database: DatabaseQueue(), notificator: notificatorMock, uploadTaskManager: CloudTaskExecutorTestCase.UploadTaskManagerMock(), cachedFileManager: CloudTaskExecutorTestCase.CachedFileManagerMock())
	}

	func testHandleNewWorkingSetUpdate() throws {
		observer.handleWorkingSetUpdate(items: updatedItems)
		XCTAssertFalse(notificatorMock.removeItemsFromWorkingSetWithCalled)
		XCTAssertFalse(notificatorMock.removeItemFromWorkingSetWithCalled)

		XCTAssertEqual(1, notificatorMock.updateWorkingSetItemsCallsCount)
		let actualUpdatedItems = notificatorMock.updateWorkingSetItemsReceivedItems as? [FileProviderItem]
		XCTAssertEqual(updatedItems.sorted(), actualUpdatedItems?.sorted())
		XCTAssertEqual(1, notificatorMock.refreshWorkingSetCallsCount)
	}

	func testHandleWorkingSetUpdateRemoveItems() throws {
		observer.handleWorkingSetUpdate(items: updatedItems)
		observer.handleWorkingSetUpdate(items: [])
		let actualRemovedItems = notificatorMock.removeItemsFromWorkingSetWithReceivedIdentifiers
		XCTAssertEqual(updatedItems.map { $0.itemIdentifier }.sorted(), actualRemovedItems?.sorted())
		XCTAssertEqual(2, notificatorMock.refreshWorkingSetCallsCount)
	}

	func testHandleWorkingSetUpdatePartiallyRemoveItems() throws {
		observer.handleWorkingSetUpdate(items: updatedItems)
		let removedItem = updatedItems.removeLast()
		observer.handleWorkingSetUpdate(items: updatedItems)
		let actualRemovedItems = notificatorMock.removeItemsFromWorkingSetWithReceivedIdentifiers
		XCTAssertEqual([removedItem.itemIdentifier].sorted(), actualRemovedItems?.sorted())
		XCTAssertEqual(2, notificatorMock.refreshWorkingSetCallsCount)
	}
}
