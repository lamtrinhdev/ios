//
//  WorkflowFactory.swift
//  CryptomatorFileProvider
//
//  Created by Philipp Schmid on 28.05.21.
//  Copyright © 2021 Skymatic GmbH. All rights reserved.
//

import CryptomatorCloudAccessCore
import Foundation
enum WorkflowFactory {
	static func createWorkflow(for deletionTask: DeletionTask, provider: CloudProvider, metadataManager: ItemMetadataManager) -> Workflow<Void> {
		let pathLockMiddleware = CreatingOrDeletingItemPathLockHandler<Void>()
		let taskExecutor = DeletionTaskExecutor(provider: provider, metadataManager: metadataManager)
		pathLockMiddleware.setNext(taskExecutor.eraseToAnyWorkflowMiddleware())
		return Workflow(middleware: pathLockMiddleware.eraseToAnyWorkflowMiddleware(), task: deletionTask, constraint: .unconstrained)
	}

	static func createWorkflow(for uploadTask: UploadTask, provider: CloudProvider, metadataManager: ItemMetadataManager, cachedFileManager: CachedFileManager, uploadTaskManager: UploadTaskManager) -> Workflow<FileProviderItem> {
		let pathLockMiddleware = CreatingOrDeletingItemPathLockHandler<FileProviderItem>()
		let onlineItemNameCollisionHandler = OnlineItemNameCollisionHandler<FileProviderItem>(itemMetadataManager: metadataManager)
		let taskExecutor = UploadTaskExecutor(provider: provider, cachedFileManager: cachedFileManager, itemMetadataManager: metadataManager, uploadTaskManager: uploadTaskManager)

		onlineItemNameCollisionHandler.setNext(taskExecutor.eraseToAnyWorkflowMiddleware())
		pathLockMiddleware.setNext(onlineItemNameCollisionHandler.eraseToAnyWorkflowMiddleware())
		return Workflow(middleware: pathLockMiddleware.eraseToAnyWorkflowMiddleware(), task: uploadTask, constraint: .uploadConstrained)
	}

	static func createWorkflow(for downloadTask: DownloadTask, provider: CloudProvider, metadataManager: ItemMetadataManager, cachedFileManager: CachedFileManager) -> Workflow<FileProviderItem> {
		let pathLockMiddleware = ReadingItemPathLockHandler<FileProviderItem>()
		let taskExecutor = DownloadTaskExecutor(provider: provider, itemMetadataManager: metadataManager, cachedFileManager: cachedFileManager)
		pathLockMiddleware.setNext(taskExecutor.eraseToAnyWorkflowMiddleware())
		return Workflow(middleware: pathLockMiddleware.eraseToAnyWorkflowMiddleware(), task: downloadTask, constraint: .downloadConstrained)
	}

	static func createWorkflow(for reparenTask: ReparentTask, provider: CloudProvider, metadataManager: ItemMetadataManager, cachedFileManager: CachedFileManager, reparentTaskManager: ReparentTaskManager) -> Workflow<FileProviderItem> {
		let pathLockMiddleware = MovingItemPathLockHandler()
		let onlineItemNameCollisionHandler = OnlineItemNameCollisionHandler<FileProviderItem>(itemMetadataManager: metadataManager)
		let taskExecutor = ReparentTaskExecutor(provider: provider, reparentTaskManager: reparentTaskManager, metadataManager: metadataManager, cachedFileManager: cachedFileManager)

		onlineItemNameCollisionHandler.setNext(taskExecutor.eraseToAnyWorkflowMiddleware())
		pathLockMiddleware.setNext(onlineItemNameCollisionHandler.eraseToAnyWorkflowMiddleware())
		return Workflow(middleware: pathLockMiddleware.eraseToAnyWorkflowMiddleware(), task: reparenTask, constraint: .unconstrained)
	}

	// swiftlint:disable:next function_parameter_count
	static func createWorkflow(for itemEnumerationTask: ItemEnumerationTask, provider: CloudProvider, metadataManager: ItemMetadataManager, cachedFileManager: CachedFileManager, reparentTaskManager: ReparentTaskManager, uploadTaskManager: UploadTaskManager, deletionTaskManager: DeletionTaskManager) -> Workflow<FileProviderItemList> {
		let pathLockMiddleware = ReadingItemPathLockHandler<FileProviderItemList>()
		let deleteItemHelper = DeleteItemHelper(metadataManager: metadataManager, cachedFileManager: cachedFileManager)
		let taskExecutor = ItemEnumerationTaskExecutor(provider: provider, itemMetadataManager: metadataManager, cachedFileManager: cachedFileManager, uploadTaskManager: uploadTaskManager, reparentTaskManager: reparentTaskManager, deletionTaskManager: deletionTaskManager, deleteItemHelper: deleteItemHelper)
		pathLockMiddleware.setNext(taskExecutor.eraseToAnyWorkflowMiddleware())
		return Workflow(middleware: pathLockMiddleware.eraseToAnyWorkflowMiddleware(), task: itemEnumerationTask, constraint: .unconstrained)
	}

	static func createWorkflow(for folderCreationTask: FolderCreationTask, provider: CloudProvider, metadataManager: ItemMetadataManager) -> Workflow<FileProviderItem> {
		let pathLockMiddleware = CreatingOrDeletingItemPathLockHandler<FileProviderItem>()
		let onlineItemNameCollisionHandler = OnlineItemNameCollisionHandler<FileProviderItem>(itemMetadataManager: metadataManager)
		let taskExecutor = FolderCreationTaskExecutor(provider: provider, itemMetadataManager: metadataManager)

		onlineItemNameCollisionHandler.setNext(taskExecutor.eraseToAnyWorkflowMiddleware())
		pathLockMiddleware.setNext(onlineItemNameCollisionHandler.eraseToAnyWorkflowMiddleware())
		return Workflow(middleware: pathLockMiddleware.eraseToAnyWorkflowMiddleware(), task: folderCreationTask, constraint: .unconstrained)
	}
}
