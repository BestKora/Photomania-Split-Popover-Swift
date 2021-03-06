//
//  AppDelegate.swift/Users/tatianakornilova/Desktop/Screen Shot 2016-02-29 at 6.21.37 PM.png
//  Photomania
//
//

import UIKit
import CoreData

// имя background download сессии для загруки данных с Flickr
let FLICKR_FETCH = "Flickr Just Uploaded Fetch"

// как часто (в секундах) мы выбираем новые фотографии,
// когда мы в активном режиме (n the foreground)
let FOREGROUND_FLICKR_FETCH_INTERVAL : Double = 20*60

// как долго мы будем ждать выборки из Flickr чтобы вернуться (return),
// когда мы в фоновом режиме (in the background)
let BACKGROUND_FLICKR_FETCH_TIMEOUT : NSTimeInterval = 10
var FLICKR_DOWNLOAD_SESSION : NSURLSession? = nil

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate,
                   NSURLSessionDownloadDelegate, UISplitViewControllerDelegate {

	// MARK: - Types
	var window: UIWindow?
    lazy var coreDataStack = CoreDataStack()

	var flickrDownloadBackgroundURLSessionCompletionHandler : (() -> Void)?
   
    // getter для свойства flickrDownloadSession
    // эту NSURLSession мы будем использовать для выборки Flickr данных в background
	var flickrDownloadSession : NSURLSession? {
		get {
			if FLICKR_DOWNLOAD_SESSION == nil {
                       // dispatch_once обеспечивает однократный запуск блока (синглтон)
				var onceToken : dispatch_once_t = 0
				dispatch_once(&onceToken){

                    // заметьте, что конфигурация здесь "backgroundSessionConfiguration:"
                    // что означает, что мы получим в конце концов результаты,
                    // даже если мы не foreground приложение,
                    // даже если приложение закончится аварийно, оно будет перезапушено (в конце концов)
                    // для обработки URL результатов!

					let urlSessionConfig = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier(FLICKR_FETCH)
					FLICKR_DOWNLOAD_SESSION = NSURLSession(configuration: urlSessionConfig,
						delegate: self, // ДОЛЖЕН быть делегат для background configurations, следовательно  delegate:self
						delegateQueue: nil) // nil для delegateQueue означает "случайная, не main queue очередь"
				}
			}
			return FLICKR_DOWNLOAD_SESSION
		}
	}
    
    var flickrForegroundFetchTimer : NSTimer?
    var photoDatabaseContext : NSManagedObjectContext?  {
        didSet {
            // мы можем что-то делать с базой данных, если контекст базы данных фотографий доступен
            // мы запускаем foreground таймер NSTimer, чтобы мы могли делать выборку
            // каждый раз в определенное время в активном режиме (in the foreground)
            
            // каждый раз при изменении контекста, мы заново стартуем наш таймер,
            // убивая (invalidate) текущий таймер
            // (к сожалению, мы не получили эту строку кода в лекции!)
            self.flickrForegroundFetchTimer?.invalidate()
            self.flickrForegroundFetchTimer = nil
            
            // этот таймер будет запускаться только когда мы в активном режиме (in the foreground)
            self.flickrForegroundFetchTimer = NSTimer.scheduledTimerWithTimeInterval(FOREGROUND_FLICKR_FETCH_INTERVAL, target: self, selector: .startFlickrFetch, userInfo: nil, repeats: true)
            
        }
	}
	
	// MARK: - UIApplicationDelegate
    
    // это вызывается как только ваш storyboard прочитан и мы готовы стартовать
    // но все равно это еще в самом начале игры (UI еще не на экране, например)
    
	func application(application: UIApplication, didFinishLaunchingWithOptions
                                                 launchOptions: [NSObject: AnyObject]?) -> Bool {

        // когда мы в фоновом режиме (in the background), производим выборку как можно чаще
        // (что на самом деле не будет часто)
        // забыл включить эту строку во время демонстрации на лекции,
        // но вы не забудьте включить ее в ваше приложение!
		UIApplication.sharedApplication().setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
		
        if let split = self.window?.rootViewController as? UISplitViewController,
            navigationMaster = split.viewControllers.first as? UINavigationController,
            topMaster = navigationMaster.topViewController
        {
            if topMaster.respondsToSelector(Selector("setCoreDataStack:")) {
                topMaster.performSelector(Selector("setCoreDataStack:"), withObject: coreDataStack)
            }
        }
                                                    
        if let split = self.window?.rootViewController as? UISplitViewController,
            navigationDetail = split.viewControllers.last as? UINavigationController {
                navigationDetail.topViewController?.navigationItem.leftBarButtonItem = split.displayModeButtonItem()
                navigationDetail.topViewController?.navigationItem.leftItemsSupplementBackButton = true
                split.delegate = self
                split.preferredDisplayMode = .AllVisible

                //  split.preferredPrimaryColumnWidthFraction = 0.5
                //  split.maximumPrimaryColumnWidth = 512

        }
                                                    
        // мы получаем managed object контекст, самостоятельно создавая его в классе CoreDataStack
        self.photoDatabaseContext = coreDataStack.managedObjectContext
		
        // мы запускаем выборку из Flickr каждый раз при старте (почему нет?)
		self.startFlickrFetch()
		

        // это возвращаемое значение должно что-то делать с обработкой URLs из других приложений
        // сейчас не беспокойтесь об этом, просто возвращайте true
		return true
	}
	
    // вызывается системой случайно, КОГДА МЫ НЕ ЯВЛЯЕМСЯ FOREGROUND APPLICATION
    // в действительности, система ЗАПУСТИТ НАС, если необходимо вызвать этот метод
    // у системы очень много разумных причин когда это сделать, но для нас это абсолютно непрозрачно
	func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        
        // на лекции мы положились на background flickrDownloadSession,
        // чтобы выполнить выборку путем вызова[self startFlickrFetch]
        // это легко кодировать, но очень слабо в том смысле, как часто эта выборка будет реально
        // происходить (может быть почти никогда)
        // это потому, что нет гарантий, что нам разрешат стартовать такого слишком своенравного выборщика,
        // который работает, когда мы находимся в фоновом режиме
        // так что давайте просто сделаем здесь несвоенравную, не background-session выборку
        // мы не хотим, чтобы она занимала слишком много времени, потому что система начнет терять доверие к нам
        // из-за background выборщика и перестанет нас часто вызывать
        // поэтому мы ограничим время выборки в BACKGROUND_FETCH_TIMEOUT секунд
        // (а также мы не будем использовать дорогостоящую сотовую передачу данных )
        
		if  (self.photoDatabaseContext != nil) {
			let sessionConfig = NSURLSessionConfiguration.ephemeralSessionConfiguration()
			sessionConfig.allowsCellularAccess = false
			sessionConfig.timeoutIntervalForRequest = BACKGROUND_FLICKR_FETCH_TIMEOUT // want to be a good background citizen!
			let session = NSURLSession(configuration: sessionConfig)
			let request = NSURLRequest(URL: FlickrFetcher.URLforRecentGeoreferencedPhotos())
			let task = session.downloadTaskWithRequest(request) {(localFile : NSURL?, response: NSURLResponse?, error : NSError?) -> Void in
				if let err = error {
					NSLog("Flickr background fetch failed: %@", err.localizedDescription)
					completionHandler(.NoData)
				}
				else {
					self.loadFlickrPhotosFromLocalURL(localFile!, intoContext: self.photoDatabaseContext){
						completionHandler(.NewData)
					}
				}
			}
			task.resume()
		}
		else {
            // не делаем обновления в переключателе приложений app-switcher, если нет database!
			completionHandler(.NoData)
		}
	}
	
    // это вызывается тогда, когда URL, который мы запросили в background сессии, возвращается,
    // а мы в фоновом режиме (in the background)
    // и он по существу "будит нас от спячки", чтобы обработать результаты URL
    // если мы в активном режиме (in the foreground), iOS просто вызывает наши методы делегата и
    // не беспокоит нас этим совсем

	func application(application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: () -> Void) {
        
        // когда вызывается этот completionHandler, то осуществляется перерисовка нашего UI
        // в переключателе приложений (app switcher),
        // но не следует вызывать этот обработчик до тех пор, пока мы не завершили обработку URL,
        // результаты которого теперь доступны
        // поэтому мы припрячем этот completionHandler в специальном свойстве до тех пор,
        // пока мы не будем готовы его вызвать
        // (смотри flickrDownloadTasksMightBeComplete, в котором он действительно вызывается)
		self.flickrDownloadBackgroundURLSessionCompletionHandler = completionHandler;
	}

	// MARK: - Flickr Fetching
	// this will probably not work (task = nil) if we're in the background, but that's okay
	// (we do our background fetching in performFetchWithCompletionHandler:)
	// it will always work when we are the foreground (active) application
	
    func startFlickrFetch() {
        
        // getTasksWithCompletionHandler: является ASYNCHRONOUS (асихронной)
        // и это нормально, потому что не ожидаем, что startFlickrFetch будет делать синхронно в любом случае
        
        self.flickrDownloadSession?.getTasksWithCompletionHandler({ (dataTasks : [NSURLSessionDataTask], uploadTasks : [NSURLSessionUploadTask], downloadTasks : [NSURLSessionDownloadTask]) -> Void in
            
            // давайте посмотрим, может быть выборки уже работают ...
            if downloadTasks.count == 0{
                // ... выборки не работают и мы запускаем одну
                let task = self.flickrDownloadSession?.downloadTaskWithURL(FlickrFetcher.URLforRecentGeoreferencedPhotos())
                task?.taskDescription = FLICKR_FETCH
                task?.resume()
            }
            else {
                // ... выборки уже работают (давайте убедимся, она (они) работает(ют), когда мы находимся здесь)
                for task in downloadTasks {
                    task.resume()
                }
            }
        })
    }
    
    // NSTimer target/action всегда использует NSTimer как аргумент
	func startFlickrFetch(timer: NSTimer) {
        self.startFlickrFetch()
	}
	
	// стандартный код для "получаем информацию о фотографиях с Flickr URL"
	func flickrPhotosAtURL(url : NSURL) -> [[String : AnyObject]]? {
		if let flickrJSONData = NSData(contentsOfURL: url) {
			let flickrPropertyList : AnyObject? = try? NSJSONSerialization.JSONObjectWithData(flickrJSONData, options: [])
			return flickrPropertyList!.valueForKeyPath(FLICKR_RESULTS_PHOTOS) as? [[String : AnyObject]]
		}
		return nil
	}
	
    // получаем словари с Flickr фотографиями из url и размещаем в Core Data
    // после лекции это переместили сюда, чтобы дать вам пример, как декларировать метод, аргументом которого является блок,
    // и потому что этот метод вызывается дважды как в части обработчика делегата background session,
    // так и в случае, когда происходит background fetch
    func loadFlickrPhotosFromLocalURL(localFile : NSURL, intoContext managedContext : NSManagedObjectContext?, whenDone : (()->())?) {
        if let context = managedContext,
            let photos = self.flickrPhotosAtURL(localFile)
        {
            context.performBlock(){
                
                // Записываем в Core Data
                _ = photos.flatMap({ (dict) -> Photo? in
                    return Photo.init(dictionary: dict, context: self.coreDataStack.managedObjectContext)
                })
                self.coreDataStack.saveMainContext()
                if let done = whenDone { done()}
            }
        }
        else {
            if let done = whenDone { done()}
        }
    }
	
	//MARK: - NSURLSessionDownloadDelegate
	
	// обязательный метод протокола
	func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didFinishDownloadingToURL localFile: NSURL) {
		// нам не следует предполагать, что мы единственные осуществляем загрузку в данный момент ...
		if downloadTask.taskDescription == FLICKR_FETCH {
			    // ... но если это Flickr выборка, то обрабатываем возвращенные данные
			self.loadFlickrPhotosFromLocalURL(localFile, intoContext: self.photoDatabaseContext){
				self.flickrDownloadTasksMightBeComplete()
			}
		}
	}
	
	
    // обязательный метод протокола
	func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didResumeAtOffset fileOffset: Int64, expectedTotalBytes: Int64) {
		    // мы не будем поддерживать возобновление прерванного задания загрузки
	}
	
    // обязательный метод протокола
	func URLSession(session: NSURLSession, downloadTask: NSURLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        // мы не будем отображать процесс загрузки на нашем UI, но это действительно крутой метод
	}
	
    // не требуется протоколом, но здесь следует ловить ошибки
    // чтобы избежать аварийного завершения
    // и также мы можем обнаружить, что задачи загрузки закончены (могут быть закончены)
	func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
		if error != nil && session == self.flickrDownloadSession! {
			NSLog("Flickr background download session failed: %@", error!.localizedDescription)
			self.flickrDownloadTasksMightBeComplete()
		}
	}
	
    // этот "может быть" на случай, если когда-то у нас будет много загрузок одновременно
	func flickrDownloadTasksMightBeComplete() {
		if (self.flickrDownloadBackgroundURLSessionCompletionHandler != nil) {
			self.flickrDownloadSession?.getTasksWithCompletionHandler({ (dataTasks : [NSURLSessionDataTask], uploadTasks : [NSURLSessionUploadTask], downloadTasks : [NSURLSessionDownloadTask]) -> Void in
                
                // мы делаем эту проверку для других загрузок, чтобы чисто теоретически "быть корректными"
                // но в действительности мы в ней не нуждаемся, (так как мы запускаем  только одну загрузку за раз)
                // дополнительно заметим, что getTasksWithCompletionHandler: является ASYNCHRONOUS
                // так что мы должны во время выполнения блока опять проверить, не установлен ли обработчик в nil
                //  (другой поток может уже послать его при multiple-tasks-at-once реализации)

				if downloadTasks.count == 0 {  // остались ли еще какие-нибудь Flickr загрузки?
					// нет, тогда вовлекаем flickrDownloadBackgroundURLSessionCompletionHandler (если он все еще не nil)
					let handler = self.flickrDownloadBackgroundURLSessionCompletionHandler
					self.flickrDownloadBackgroundURLSessionCompletionHandler = nil
					if let download = handler {
						download()
					}
				}
				// иначе другие загрузки продолжаются, так что позволим им вызвать этот метод, когда они финишируют
			})
		}
	}
    
    // MARK: - Split view
    
    func splitViewController(splitViewController: UISplitViewController,
                                          separateSecondaryViewControllerFromPrimaryViewController
                                   primaryViewController: UIViewController) -> UIViewController? {
            
            guard let masterAsNav = primaryViewController as? UINavigationController,
                  let masterView = masterAsNav.topViewController as? PhotosByPhotographerCDTVC
            else { return nil }
            
            //-------- Detail----
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            guard let detailAsNav =
                storyboard.instantiateViewControllerWithIdentifier("detailNavigation")
                    as? UINavigationController,
                let controller = detailAsNav.visibleViewController as? ImageViewController
                else { return nil }
            
            // Выделяем первую строку
            let indexPath = NSIndexPath(forRow: 0, inSection: 0)
            masterView.tableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: .Top)
            
            // Обеспечиваем появление обратной кнопки
            controller.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem()
            controller.navigationItem.leftItemsSupplementBackButton = true
            
            //--------Настройка Модели на первое photo ----
            if let photo = (masterView.fetchedResultsController?.objectAtIndexPath(indexPath)) as? Photo {
                controller.imageURL = NSURL(string: photo.imageURL)
                controller.title = photo.title
            }
            return detailAsNav
    }
  
    func splitViewController(splitViewController: UISplitViewController,
                      collapseSecondaryViewController secondaryViewController:UIViewController,
                      ontoPrimaryViewController primaryViewController:UIViewController) -> Bool {
                        
                        guard let navigationDetail = secondaryViewController as? UINavigationController,
                              let topDetail = navigationDetail.topViewController as? ImageViewController
                            where topDetail.imageURL == nil
                            else {return false}
                        
                        // Возврат true сигнализирует, что Detail должен быть отброшен
                        return true
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        coreDataStack.saveMainContext()
    }
}

private extension Selector {
    static let startFlickrFetch =
        #selector(AppDelegate.startFlickrFetch(_:))
}
