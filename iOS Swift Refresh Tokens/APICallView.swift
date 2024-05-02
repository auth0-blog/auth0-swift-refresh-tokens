//
//  APICallView.swift
//  iOS Swift Protected API Call
//
//  Created by Auth0 on 3/27/24.
//  Companion project for the Auth0 Blog
//  “Calling a protected API from an iOS Swift App”
//

import SwiftUI
import Auth0

struct Event: Identifiable, Codable {
    let id: Int
    let title: String
    let body: String
}

enum NetworkError: Error {
    case badUrl
    case invalidRequest
    case badResponse
    case badStatus
    case failedToDecodeResponse
}

@available(iOS 15.0, *)
public class Delegate: NSObject, URLSessionDelegate, URLSessionTaskDelegate, URLSessionDataDelegate {
//    private var session: URLSession! = nil
    
//    private var dataTask: URLSessionDataTask?
    
//    private var sessionTask: URLSessionTask?
    
/*
    public init(urlSession:URLSession? = nil) {
        super.init()
        if urlSession != nil {
            self.session = urlSession!
        } else {
            let config = URLSessionConfiguration.default
            config.requestCachePolicy = .reloadIgnoringLocalCacheData
            self.session = URLSession(configuration: config, delegate: self, delegateQueue: .main)
        }
    }
*/
    
    public override init() {
        super.init()
    }
    
/*
    let urlString_redirect = "http:www.apple.com"
    let urlString_json = "https://jsonplaceholder.typicode.com/posts/1"
    let urlString_auth = "https://httpbin.org/basic-auth/hello/dolly"
*/
 
   
/*
    public func simpleGet() async throws {
        let url = URL(string:urlString_json)!
        let (data, response) = try await self.session.data(from:url, delegate: self)
        print(sessionTask?.state.rawValue)
        print(sessionTask?.progress)
        print(sessionTask?.progress.fileOperationKind)
        let httpResponse = response as? HTTPURLResponse
        print("Task \(sessionTask?.description ?? "") heard \(httpResponse?.statusCode ?? 0)")
        print(await session.tasks)
        print("I got data. \(data.count)")
    }
*/
  
/*
    public func simpleDataTask() {
        let url = URL(string:urlString_json)!
        self.dataTask = self.session.dataTask(with: URLRequest(url: url))
        dataTask?.resume()
    }
    
*/
    
    //MARK: WORKS .data & .dataTask
/*
    public func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask) {
        print("I made a task:\(task)")
//        self.sessionTask = task
    }
*/

/*
    //fires on finish
    public func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        print("metrics for \(task) recieved.")
        //print(metrics)
    }
*/
/*
    public func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest) async -> URLRequest? {
        print("redirecting... \(String(describing: request.url))")
        return request
    }
*/
    //MARK: Worked JUST for .data
    //presumably the one with a completion handler is for .dataTask
    //but was challenge even maybe when wasn't supposed to have been?
    public func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge
    ) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        print("challenged \(task) with \(challenge)")
        
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodHTTPBasic {
//        do {
            let (username, password) = ("hello", "dolly")
            return (.useCredential, URLCredential(user: username, password: password, persistence: .forSession))
//        } catch {
//          return (.cancelAuthenticationChallenge, nil)
//        }
        } else {
            return (.performDefaultHandling, nil)
        }
    }

    //MARK: Works with dataTask only
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse) async -> URLSession.ResponseDisposition {
        let httpResponse = response as? HTTPURLResponse
        print("Task \(dataTask) heard \(httpResponse?.statusCode ?? 0)")
        return URLSession.ResponseDisposition.allow
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        print("I heard that...\(data.count)")
        //NSLog("task data: %@", data as NSData)
        //print("task data: %@", data as NSData)
    }

    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error as NSError? {
            //NSLog("task error: %@ / %d", error.domain, error.code)
            print("task error: %@ / %d", error.domain, error.code)
        } else {
            print("task complete")
            //NSLog("task complete")
        }
    }
    
    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome downloadTask: URLSessionDownloadTask) {
        print("downLoadTask\(downloadTask) from dataTask \(dataTask)")
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didBecome streamTask: URLSessionStreamTask) {
        print("streamTask\(streamTask) from dataTask \(dataTask)")
    }

/*
    //auth catch for data task.
    public func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
       print("challenged with \(challenge)")
       //No idea what else to do.
    }
*/
    
/*
    public func urlSession(_ session: URLSession, task: URLSessionTask, willBeginDelayedRequest request: URLRequest) async -> (URLSession.DelayedRequestDisposition, URLRequest?) {
        print("downLoadTask\(downloadTask) from dataTask \(dataTask)")
    }
*/
}

class WebService: Codable {
    func credentials() async throws -> Credentials {
        let credentialsManager = CredentialsManager(authentication: Auth0.authentication())
        
        return try await withCheckedThrowingContinuation { continuation in
            credentialsManager.credentials { result in
                switch result {
                case .success(let credentials):
                    continuation.resume(returning: credentials)
                    break

                case .failure(let reason):
                    continuation.resume(throwing: reason)
                    break
                }
            }
        }
    }
    
    func downloadData<T: Codable>(fromURL: String) async -> T? {
        do {
            guard let url = URL(string: fromURL) else { throw NetworkError.badUrl }
            var request = URLRequest(url: url)
            let credentials = try await credentials();
            
            /* Convention is for an Access Token to be supplied as Authorization Bearer in the header of an HTTP request. Apple's documentation is somewhat ambiguious when it comes to how do this, so for the purpose of this example I'll follow the advice suggested at https://ampersandsoftworks.com/posts/bearer-authentication-nsurlsession/
             */
            request.setValue("Bearer \(credentials.accessToken)", forHTTPHeaderField: "Authorization")
            
//            let (data, result) = try await URLSession.shared.data(for: request, delegate: Delegate())
//            let (data, result) = try await URLSession(configuration: .ephemeral).data(for: request, delegate: Delegate())
            let (data, result) = try await URLSession(configuration: .ephemeral).data(for: request)
            guard let response = result as? HTTPURLResponse else { throw NetworkError.badResponse }
            guard response.statusCode >= 200 && response.statusCode < 300 else { throw NetworkError.badStatus }
            guard let decodedResponse = try? JSONDecoder().decode(T.self, from: data) else { throw NetworkError.failedToDecodeResponse }
            return decodedResponse
        } catch NetworkError.badUrl {
            print("There was an error creating the URL")
        } catch NetworkError.badResponse {
            print("Did not get a valid response")
        } catch NetworkError.badStatus {
            print("Did not get a 2xx status code from the response")
        } catch NetworkError.failedToDecodeResponse {
            print("Failed to decode response into the given type")
        } catch {
            print("An error occured downloading the data")
        }
        
        return nil
    }
}

class EventViewModel: ObservableObject {
    @Published var eventData = [Event]()
    
    func fetchData() async {
        if let path = Bundle.main.path(forResource: "API", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path) as? [String: AnyObject] {
            // use swift dictionary as normal
            if let url = dict["Events"] as? String {
                guard let downloadedEvents: [Event] = await WebService().downloadData(fromURL: url) else {return}
                DispatchQueue.main.async {
                    self.eventData = downloadedEvents
                }
            }
        }
    }
}

struct APICallView: View {
    @StateObject var vm = EventViewModel()
    
    @Binding var isAPICall: Bool
    
    var body: some View {
        List(vm.eventData) { event in
            HStack {
                Text("\(event.id)")
                    .padding()
                    .overlay(Circle().stroke(.blue))
                
                VStack(alignment: .leading) {
                    Text(event.title)
                        .bold()
                        .lineLimit(1)
                    
                    Text(event.body)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .onAppear {
            if vm.eventData.isEmpty {
                Task {
                    await vm.fetchData()
                }
            }
        }
        
        if (!vm.eventData.isEmpty) {
            HStack {
                Button("Done") {
                    isAPICall = false;
                }
                .buttonStyle(MyButtonStyle())
            } // HStack
        }
    }
    
    struct MyButtonStyle: ButtonStyle {
        let blueGreen = Color(red: 0, green: 0.5, blue: 0.5)
      
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
              .padding()
              .background(blueGreen)
              .foregroundColor(.white)
              .clipShape(Capsule())
        }
    }
}

/*
#Preview {
    APICallView()
}
*/
