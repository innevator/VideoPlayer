//
//  PlayListViewControllerTests.swift
//  iOSVideoPlayerTests
//
//  Created by 洪宗鴻 on 2024/6/6.
//

import XCTest
import VideoPlayer
@testable import iOSVideoPlayer

class PlayListViewControllerTests: XCTestCase {
    
    func test_initializeHasNoDefaultData() {
        let (sut, _) = makeSUT()
        let renderedViewsCount = sut.numberOfRenderedPlayListViews()
        
        XCTAssertEqual(renderedViewsCount, 0)
    }
    
    func test_viewSetupWhenViewAppear() {
        let (sut, _) = makeSUT()
        
        sut.simulateAppearance()
        
        XCTAssertEqual(sut.title, String(.playListTitle))
        XCTAssertNotNil(sut.tableView.delegate)
        XCTAssertNotNil(sut.tableView.dataSource)
        XCTAssertNotNil(sut.tableView.superview)
    }
    
    func test_loadPlayListActions_loadDataFromService() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        
        XCTAssertEqual(loader.loadStreamCallCount, 1)
    }
    
    func test_loadPlayListDataFromService_success() {
        let (sut, loader) = makeSUT()
        let items = [makeUniqeStream(), makeUniqeStream()]
        
        sut.simulateAppearance()
        loader.complete(with: .success(items))
        
        XCTAssertEqual(sut.numberOfRenderedPlayListViews(), 2)
        XCTAssertEqual(sut.simulatePlayListViewVisible()?.textLabel?.text, items[0].name)
        XCTAssertEqual(sut.simulatePlayListViewVisible()?.textLabel?.text, items[1].name)
    }
    
    func test_loadPlayListDataFromService_failedWithError() {
        let routerSpy = RouterSpy()
        let (sut, loader) = makeSUT(router: routerSpy)
        
        sut.simulateAppearance()
        loader.complete(with: .failure(anyError))
        
        XCTAssertEqual(sut.numberOfRenderedPlayListViews(), 0)
        
        switch routerSpy.view {
        case .alert(let title, let message, let actions):
            XCTAssertEqual(title, String(.getAssetsFailedAlertTitle))
            XCTAssertEqual(message, nil)
            XCTAssertEqual(actions.first?.title, String(.getAssetsFailedAlertActionTitle))
        default:
            XCTFail("should present alert with error")
        }
    }
    
    func test_goPlayVideo() {
        let routerSpy = RouterSpy()
        let (sut, loader) = makeSUT(router: routerSpy)
        let items = [makeUniqeStream(), makeUniqeStream()]
        
        sut.simulateAppearance()
        loader.complete(with: .success(items))
        sut.simulateTapPlayVideo(at: 0)
        
        switch routerSpy.view {
        case .playVideo(let assets):
            assets.enumerated().forEach { index, asset in
                XCTAssertEqual(asset.getStream(), items[index])
            }
        default:
            XCTFail("should present playVideoVC")
        }
    }
    
    // MARK: - Helper
    
    private func makeSUT(router: Router = Router()) -> (sut: PlayListViewController, loader: LoaderSpy) {
        let loader = LoaderSpy()
        let vc = PlayListViewController(router: router, service: AssetService(loader: loader))
        return (vc, loader)
    }
    
    private func makeUniqeStream() -> VideoPlayer.Stream {
        return Stream(id: UUID().uuidString, name: "a name", url: "http://a-url.com")
    }
    
    private var anyError: NSError {
        NSError(domain: "", code: 0)
    }
    
    private class LoaderSpy: StreamLoader {
        private var streamRequests: [(StreamLoader.Result) -> Void] = []
        
        var loadStreamCallCount: Int {
            return streamRequests.count
        }
        
        func load(completion: @escaping (StreamLoader.Result) -> Void) {
            streamRequests.append(completion)
        }
        
        func complete(with result: StreamLoader.Result, at index: Int = 0) {
            streamRequests[index](result)
        }
    }
                       
    private class RouterSpy: Router {
        private(set) var view: Router.RoutableView?
        
        override func go(_ routable: Router.RoutableView) {
            view = routable
        }
    }
}
