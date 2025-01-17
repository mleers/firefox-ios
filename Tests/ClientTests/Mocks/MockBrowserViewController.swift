// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
@testable import Client

class MockBrowserViewController: BrowserViewController {
    var switchToPrivacyModeCalled = false
    var switchToPrivacyModeIsPrivate = false
    var switchToTabForURLOrOpenCalled = false
    var switchToTabForURLOrOpenURL: URL?
    var switchToTabForURLOrOpenUUID: String?
    var switchToTabForURLOrOpenIsPrivate = false

    var openBlankNewTabCalled = false
    var openBlankNewTabFocusLocationField = false
    var openBlankNewTabIsPrivate = false
    var openBlankNewTabSearchText: String?

    var handleQueryCalled = false
    var handleQuery: String?
    var showLibraryCalled = false
    var showLibraryPanel: LibraryPanelType?

    var openURLInNewTabCalled = false
    var openURLInNewTabURL: URL?
    var openURLInNewTabIsPrivate = false

    var switchToPrivacyModeCount = 0
    var switchToTabForURLOrOpenCount = 0
    var openBlankNewTabCount = 0
    var handleQueryCount = 0
    var showLibraryCount = 0
    var openURLInNewTabCount = 0

    var presentSignInFxaOptions: FxALaunchParams?
    var presentSignInFlowType: FxAPageType?
    var presentSignInReferringPage: ReferringPage?
    var presentSignInCount: Int = 0

    var qrCodeCount = 0
    var closePrivateTabsCount = 0

    override func switchToPrivacyMode(isPrivate: Bool) {
        switchToPrivacyModeCalled = true
        switchToPrivacyModeIsPrivate = isPrivate
        switchToPrivacyModeCount += 1
    }

    override func switchToTabForURLOrOpen(_ url: URL, uuid: String?, isPrivate: Bool) {
        switchToTabForURLOrOpenCalled = true
        switchToTabForURLOrOpenURL = url
        switchToTabForURLOrOpenUUID = uuid
        switchToTabForURLOrOpenIsPrivate = isPrivate
        switchToTabForURLOrOpenCount += 1
    }

    override func openBlankNewTab(focusLocationField: Bool, isPrivate: Bool, searchFor searchText: String?) {
        openBlankNewTabCalled = true
        openBlankNewTabFocusLocationField = focusLocationField
        openBlankNewTabIsPrivate = isPrivate
        openBlankNewTabSearchText = searchText
        openBlankNewTabCount += 1
    }

    override func handle(query: String) {
        handleQueryCalled = true
        handleQuery = query
        handleQueryCount += 1
    }

    override func showLibrary(panel: LibraryPanelType?) {
        showLibraryCalled = true
        showLibraryPanel = panel
        showLibraryCount += 1
    }

    override func openURLInNewTab(_ url: URL?, isPrivate: Bool) {
        openURLInNewTabCalled = true
        openURLInNewTabURL = url
        openURLInNewTabIsPrivate = isPrivate
        openURLInNewTabCount += 1
    }

    override func handleQRCode() {
        qrCodeCount += 1
    }

    override func handleClosePrivateTabs() {
        closePrivateTabsCount += 1
    }

    override func presentSignInViewController(_ fxaOptions: FxALaunchParams, flowType: FxAPageType = .emailLoginFlow, referringPage: ReferringPage = .none) {
        presentSignInFxaOptions = fxaOptions
        presentSignInFlowType = flowType
        presentSignInReferringPage = referringPage
        presentSignInCount += 1
    }
}
