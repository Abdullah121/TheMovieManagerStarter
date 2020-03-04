//
//  MovieDetailViewController.swift
//  TheMovieManager
//
//  Created by Owen LaRosa on 8/13/18.
//  Copyright © 2018 Udacity. All rights reserved.
//

import UIKit

class MovieDetailViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var watchlistBarButtonItem: UIBarButtonItem!
    @IBOutlet weak var favoriteBarButtonItem: UIBarButtonItem!
    
    var movie: Movie!
    
    var isWatchlist: Bool {
        return MovieModel.watchlist.contains(movie)
    }
    
    var isFavorite: Bool {
        return MovieModel.favorites.contains(movie)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = movie.title
        
        toggleBarButton(watchlistBarButtonItem, enabled: isWatchlist)
        toggleBarButton(favoriteBarButtonItem, enabled: isFavorite)
        
        self.imageView?.image = UIImage(named: "PosterPlaceholder")
        if let posterPath = movie.posterPath {
            TMDBClient.downloadPosterImage(path: posterPath) { (data, error) in
                guard let data = data else{
                    return
                }
                let image = UIImage(data: data)
                self.imageView.image = image
            }
        }
        
    }
    
    @IBAction func watchlistButtonTapped(_ sender: UIBarButtonItem) {
        TMDBClient.markWatchlist(movieId: movie.id, watchlist: !isWatchlist, completion: self.handleWatchlistResponse(success:error:) )
        
    }
    
    @IBAction func favoriteButtonTapped(_ sender: UIBarButtonItem) {
        TMDBClient.markFavourite(movieId: movie.id, favorite: !isFavorite, completion: self.handleFavoriteResponse(success:error:))
    }
    
    func toggleBarButton(_ button: UIBarButtonItem, enabled: Bool) {
        if enabled {
            button.tintColor = UIColor.primaryDark
        } else {
            button.tintColor = UIColor.gray
        }
    }
    
    func handleWatchlistResponse(success: Bool , error: Error?){
        if success{
            if isWatchlist{
                MovieModel.watchlist = MovieModel.watchlist.filter({ (movie) -> Bool in
                    movie != self.movie
                })
            }
            else{
                MovieModel.watchlist.append(self.movie)
            }
        }
        
        toggleBarButton(watchlistBarButtonItem, enabled: isWatchlist)
    }
    
    func handleFavoriteResponse(success: Bool , error: Error?){
        if success{
            if isFavorite{
                MovieModel.favorites = MovieModel.favorites.filter({ (movie) -> Bool in
                    movie != self.movie
                })
            }
            else{
                MovieModel.favorites.append(self.movie)
            }
        }
        
        toggleBarButton(favoriteBarButtonItem, enabled: isFavorite)
    }
    
    
}
