import Foundation

class TMDBClient {
    
    static let apiKey = "03bb81de39483be299593f33a7d21867"
    
    struct Auth {
        static var accountId = 0
        static var requestToken = ""
        static var sessionId = ""
    }
    
    enum Endpoints {
        static let base = "https://api.themoviedb.org/3"
        static let apiKeyParam = "?api_key=\(TMDBClient.apiKey)"
        
        case getWatchlist
        case getFavourite
        case getRequestToken
        case login
        case createSessionId
        case webAuth
        case logout
        case search(String)
        case markWatchlist
        case markFavorite
        case posterImage(String)
        
        var stringValue: String {
            switch self {
            case .getWatchlist: return Endpoints.base + "/account/\(Auth.accountId)/watchlist/movies" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
                
            case .getFavourite: return Endpoints.base + "/account/\(Auth.accountId)/favorite/movies" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
                
            case .search(let query): return Endpoints.base + "/search/movie" + Endpoints.apiKeyParam + "&query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
                
            case .getRequestToken: return Endpoints.base + "/authentication/token/new" + Endpoints.apiKeyParam
                
            case .login: return Endpoints.base + "/authentication/token/validate_with_login" + Endpoints.apiKeyParam
                
            case .createSessionId: return Endpoints.base + "/authentication/session/new" + Endpoints.apiKeyParam
                
            case .webAuth: return "https://www.themoviedb.org/authenticate/" + Auth.requestToken + "?redirect_to=themoviemanager:authenticate"
                
            case .logout: return Endpoints.base + "/authentication/session" + Endpoints.apiKeyParam
                
            case .markWatchlist: return Endpoints.base + "/account/\(Auth.accountId)/watchlist" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
                
            case .markFavorite: return Endpoints.base + "/account/\(Auth.accountId)/favorite" + Endpoints.apiKeyParam + "&session_id=\(Auth.sessionId)"
                
            case .posterImage(let posterPath): return "https://image.tmdb.org/t/p/w500" + posterPath
        
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    class func logout(completion: @escaping ()->Void) {
        var request = URLRequest(url: Endpoints.logout.url)
        request.httpMethod = "DELETE"
        let body = LogoutRequest(sessionId: self.Auth.sessionId)
        let json = try! JSONEncoder().encode(body)
        request.httpBody = json
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            Auth.requestToken = ""
            Auth.sessionId = ""
            completion()
        }
        task.resume()
    }
    
    
    class func createSession(completion: @escaping (Bool, Error?)->Void){
        
        let body = PostSession(requestToken: self.Auth.requestToken)
        
        taskForPOSTRequest(url: Endpoints.createSessionId.url, responseType: SessionResponse.self, body: body) { (response, error) in
            
            guard let response = response else{
                completion(false, error)
                return
            }
            Auth.sessionId = response.sessionId
            completion(true,nil)
        }
    }
    
    class func login(username: String, password: String, completion: @escaping (Bool, Error?)->Void){
        var request = URLRequest(url: Endpoints.login.url)
        request.httpMethod = "POST"
        let body = LoginRequest(username: username, password: password, requestToken: Auth.requestToken)
        
        
        taskForPOSTRequest(url: Endpoints.login.url, responseType: RequestTokenResponse.self, body: body) { (response, error) in
            
            guard let response = response else{
                completion(false, error)
                return
            }
            Auth.requestToken = response.requestToken
            completion(true,nil)
        }
        
    }
    
    class func getRequestToken(completion : @escaping (Bool, Error?)->Void){
        taskForGetRequest(url: Endpoints.getRequestToken.url, response: RequestTokenResponse.self) { (response, error) in
            guard let response = response else {
                completion(false, error)
                return
            }
            Auth.requestToken = response.requestToken
            completion(true, nil)
            
        }
    }
    
    class func getWatchlist(completion: @escaping ([Movie], Error?) -> Void) {
        
        taskForGetRequest(url: Endpoints.getWatchlist.url, response: MovieResults.self) { (response, error) in
            guard let response = response else {
                completion([], error)
                return
            }
            completion(response.results, nil)
        }
    }
    
    class func getFavouritelist(completion: @escaping ([Movie], Error?) -> Void) {
        
        taskForGetRequest(url: Endpoints.getFavourite.url, response: MovieResults.self) { (response, error) in
            guard let response = response else {
                completion([], error)
                return
            }
            completion(response.results, nil)
        }
    }
    
    class func search(query: String, completion: @escaping ([Movie], Error?) -> Void)-> URLSessionTask {
        
        let task = taskForGetRequest(url: Endpoints.search(query).url, response: MovieResults.self) { (response, error) in
            guard let response = response else {
                completion([], error)
                return
            }
            completion(response.results, nil)
        }
        return task
    }
    
    @discardableResult class func taskForGetRequest<ResponseType: Decodable>(url: URL, response: ResponseType.Type, completion: @escaping (ResponseType?, Error?)->Void)-> URLSessionTask {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            } catch {
//                do{
//                    let errorResponse = try decoder.decode(TMDBResponse.self, from: data)
//                    DispatchQueue.main.async {
//                        completion(nil, errorResponse)
//                    }
//                }catch{
//                    DispatchQueue.main.async {
//                        completion(nil, error)
//                    }
//                }
                
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                    
            }
        }
        task.resume()
        return task
    }
    
    class func taskForPOSTRequest<RequestType: Encodable, ResponseType: Decodable>(url: URL, responseType: ResponseType.Type, body: RequestType, completion: @escaping (ResponseType?, Error?) -> Void){
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let json = try! JSONEncoder().encode(body)
        request.httpBody = json
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            do{
                let decoder = JSONDecoder()
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                //Auth.requestToken = responseObject.requestToken
                DispatchQueue.main.async {
                    completion(responseObject, error)
                }
            }catch{
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
        task.resume()
    }
    
    class func markWatchlist(movieId: Int, watchlist: Bool, completion: @escaping (Bool, Error?)->Void){
        let body = MarkWatchlist(mediaType: "movie", mediaId: movieId ,watchlist: watchlist)
        
        taskForPOSTRequest(url: Endpoints.markWatchlist.url, responseType: TMDBResponse.self, body: body) { (response, error) in
            guard let response = response else{
                completion(false, error)
                return
            }
            completion(response.statusCode==1 || response.statusCode==12 || response.statusCode==13,nil)
        }
    }
    
    class func markFavourite(movieId: Int, favorite: Bool, completion: @escaping (Bool, Error?)->Void){
        let body = MarkFavorite(mediaType: "movie", mediaId: movieId ,favorite: favorite)
        
        taskForPOSTRequest(url: Endpoints.markFavorite.url, responseType: TMDBResponse.self, body: body) { (response, error) in
            guard let response = response else{
                completion(false, error)
                return
            }
            completion(response.statusCode==1 || response.statusCode==12 || response.statusCode==13,nil)
        }
    }
    
    class func downloadPosterImage(path: String, completion: @escaping (Data?, Error?)->Void){
        let task = URLSession.shared.dataTask(with: Endpoints.posterImage(path).url) { (data, response, error) in
            guard let data = data else{
                DispatchQueue.main.async {
                    completion(nil,error)
                }
                return
            }
            DispatchQueue.main.async {
                completion(data,nil)
            }
        }
        
        task.resume()
    }
}
