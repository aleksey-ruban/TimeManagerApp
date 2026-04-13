import UIKit

public enum ImageResolverSource {
    case automatic
    case assetCatalog
    case systemSymbol
}

@MainActor
public enum ImageResolver {
    public static func resolve(
        named imageName: String,
        in bundle: Bundle? = nil,
        source: ImageResolverSource = .automatic,
        symbolConfiguration: UIImage.SymbolConfiguration? = nil
    ) -> UIImage? {
        switch source {
        case .assetCatalog:
            return UIImage(named: imageName, in: bundle, compatibleWith: nil)
        case .systemSymbol:
            return UIImage(systemName: imageName, withConfiguration: symbolConfiguration)
        case .automatic:
            if let assetImage = UIImage(named: imageName, in: bundle, compatibleWith: nil) {
                return assetImage
            }

            return UIImage(systemName: imageName, withConfiguration: symbolConfiguration)
        }
    }
}

@MainActor
public final class ImageResolverImageView: UIImageView {
    public var imageName: String? {
        didSet {
            reloadImage()
        }
    }

    public var resolverSource: ImageResolverSource {
        didSet {
            reloadImage()
        }
    }

    public var imageBundle: Bundle? {
        didSet {
            reloadImage()
        }
    }

    public var resolverSymbolConfiguration: UIImage.SymbolConfiguration? {
        didSet {
            reloadImage()
        }
    }

    public init(
        imageName: String? = nil,
        resolverSource: ImageResolverSource = .automatic,
        imageBundle: Bundle? = nil,
        preferredSymbolConfiguration: UIImage.SymbolConfiguration? = nil
    ) {
        self.imageName = imageName
        self.resolverSource = resolverSource
        self.imageBundle = imageBundle
        self.resolverSymbolConfiguration = preferredSymbolConfiguration
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        clipsToBounds = true
        contentMode = .scaleAspectFit
        tintColor = .label
        reloadImage()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setImage(named imageName: String?) {
        self.imageName = imageName
    }

    public func reloadImage() {
        guard let imageName, imageName.isEmpty == false else {
            image = nil
            return
        }

        image = ImageResolver.resolve(
            named: imageName,
            in: imageBundle,
            source: resolverSource,
            symbolConfiguration: resolverSymbolConfiguration
        )
    }
}
