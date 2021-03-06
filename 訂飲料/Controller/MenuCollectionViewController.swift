import UIKit

class MenuCollectionViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var drinkCategories:[DrinkCategory] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        DataManager.shared.fetchMenu() { result in
            switch result {
            case .success(let drinkCategories):
                self.updateUI(with: drinkCategories)
            case .failure(let error):
                self.displayError(error, title: "Failed to fetch data!")
            }
        }
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        configureCellSize()
    }
    
    func updateUI(with drinkCategories:[DrinkCategory]) {
        self.drinkCategories = drinkCategories
        DispatchQueue.main.async {
            self.collectionView.reloadData()
        }
    }
    
    func displayError(_ error: Error, title: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: error.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: - Segue
    @IBSegueAction func showDrinkView(_ coder: NSCoder) -> DrinkViewController? {
        guard let indexPath = collectionView.indexPathsForSelectedItems else { return DrinkViewController(coder: coder, selectedDrink: drinkCategories[0].drinks[0])}
        let drink = drinkCategories[indexPath[0][0]].drinks[indexPath[0][1]]
        return DrinkViewController(coder: coder, selectedDrink: drink)
    }
    
    @IBAction func unwindToMenu(_ segue: UIStoryboardSegue) {
    }
    
}

// MARK: - Collection View
extension MenuCollectionViewController: UICollectionViewDelegate, UICollectionViewDataSource {
        
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let menuHeaderView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "MenuHeader", for: indexPath) as! MenuHeaderView
        menuHeaderView.headerLabel.text = String(drinkCategories[indexPath.section].name)
        return menuHeaderView
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return drinkCategories.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return drinkCategories[section].drinks.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MenuCell", for: indexPath) as! MenuCollectionViewCell
        let drink = drinkCategories[indexPath.section].drinks[indexPath.row]
        let url = drink.thumbnailURL
        DataManager.shared.fetchImage(url: url) { image in
            guard let image = image else { return }
            DispatchQueue.main.async {
                cell.drinkThumbnail.image = image
                cell.indicatorView.isHidden = true
            }
        }
        cell.drinkName.text = drink.name
        if drink.priceM != nil && drink.priceL != nil {
            cell.drinkPrice.text = "M \(drink.priceM!) / L \(drink.priceL!)"
        } else if let priceM = drink.priceM {
            cell.drinkPrice.text = "M \(priceM)"
        } else {
            cell.drinkPrice.text = "L \(drink.priceL!)"
        }

        return cell
    }
    
    func configureCellSize() {
        let itemSpace: CGFloat = 0
        let columnCount: CGFloat = 2
        
        let flowLayout = UICollectionViewFlowLayout()
        let width = floor((collectionView.bounds.width - itemSpace * (columnCount-1)) / columnCount)
        flowLayout.itemSize = CGSize(width: width, height: width+50)
        flowLayout.estimatedItemSize = .zero //UICollectionViewFlowLayout.automaticSize
        flowLayout.minimumInteritemSpacing = itemSpace
        flowLayout.minimumLineSpacing = itemSpace
        flowLayout.headerReferenceSize = CGSize(width: 0, height: 50)
        flowLayout.sectionHeadersPinToVisibleBounds = true
        
        collectionView.collectionViewLayout = flowLayout
    }
}

