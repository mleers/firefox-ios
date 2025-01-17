// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Common
import Shared

protocol OnboardingCardDelegate: AnyObject {
    func showNextPage(_ cardType: IntroViewModel.InformationCards)
    func primaryAction(_ cardType: IntroViewModel.InformationCards)
    func pageChanged(_ cardType: IntroViewModel.InformationCards)
}

class OnboardingCardViewController: UIViewController, Themeable {
    struct UX {
        static let stackViewSpacing: CGFloat = 24
        static let stackViewSpacingButtons: CGFloat = 16
        static let buttonHeight: CGFloat = 45
        static let buttonCornerRadius: CGFloat = 13
        static let topStackViewSpacing: CGFloat = 16
        static let stackViewPadding: CGFloat = 16
        static let buttomStackViewPadding: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 32 : 24
        static let topStackViewPadding: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 70 : 90
        static let horizontalTopStackViewPadding: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 100 : 24
        static let scrollViewVerticalPadding: CGFloat = 62
        static let buttonVerticalInset: CGFloat = 12
        static let buttonHorizontalInset: CGFloat = 16
        static let buttonFontSize: CGFloat = 16
        static let titleFontSize: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 28 : 22
        static let descriptionBoldFontSize: CGFloat = 20
        static let descriptionFontSize: CGFloat = 17
        static let imageViewSize = CGSize(width: 240, height: 300)

        // small device
        static let smallTitleFontSize: CGFloat = 20
        static let smallStackViewSpacing: CGFloat = 8
        static let smallStackViewSpacingButtons: CGFloat = 16
        static let smallScrollViewVerticalPadding: CGFloat = 20
        static let smallImageViewSize = CGSize(width: 240, height: 300)
        static let smallTopStackViewPadding: CGFloat = 40

        // tiny device (SE 1st gen)
        static let tinyImageViewSize = CGSize(width: 144, height: 180)
    }

    var viewModel: OnboardingCardProtocol
    weak var delegate: OnboardingCardDelegate?
    var notificationCenter: NotificationProtocol
    var themeManager: ThemeManager
    var themeObserver: NSObjectProtocol?

    // Adjusting layout for devices with height lower than 667
    // including now iPhone SE 2nd generation and iPad
    var shouldUseSmallDeviceLayout: Bool {
        return view.frame.height <= 667 || UIDevice.current.userInterfaceIdiom == .pad
    }

    // Adjusting layout for tiny devices (iPhone SE 1st generation)
    var shouldUseTinyDeviceLayout: Bool {
        return UIDevice().isTinyFormFactor
    }

    private lazy var scrollView: UIScrollView = .build { view in
        view.backgroundColor = .clear
    }

    lazy var containerView: UIView = .build { view in
        view.backgroundColor = .clear
    }

    lazy var contentContainerView: UIView = .build { stack in
        stack.backgroundColor = .clear
    }

    lazy var topStackView: UIStackView = .build { stack in
        stack.backgroundColor = .clear
        stack.alignment = .center
        stack.distribution = .fill
        stack.spacing = UX.topStackViewSpacing
        stack.axis = .vertical
    }

    lazy var contentStackView: UIStackView = .build { stack in
        stack.backgroundColor = .clear
        stack.alignment = .center
        stack.distribution = .equalSpacing
        stack.spacing = UX.stackViewSpacing
        stack.axis = .vertical
    }

    lazy var imageView: UIImageView = .build { imageView in
        imageView.contentMode = .scaleAspectFit
        imageView.accessibilityIdentifier = "\(self.viewModel.infoModel.a11yIdRoot)ImageView"
    }

    private lazy var titleLabel: UILabel = .build { label in
        label.numberOfLines = 0
        label.textAlignment = .center
        let fontSize = self.shouldUseSmallDeviceLayout ? UX.smallTitleFontSize : UX.titleFontSize
        label.font = DynamicFontHelper.defaultHelper.preferredBoldFont(withTextStyle: .largeTitle,
                                                                       size: fontSize)
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityIdentifier = "\(self.viewModel.infoModel.a11yIdRoot)TitleLabel"
    }

    // Only available for Welcome card and default cases
    private lazy var descriptionBoldLabel: UILabel = .build { label in
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = DynamicFontHelper.defaultHelper.preferredBoldFont(withTextStyle: .title3,
                                                                       size: UX.descriptionBoldFontSize)
        label.isHidden = true
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityIdentifier = "\(self.viewModel.infoModel.a11yIdRoot)DescriptionBoldLabel"
    }

    private lazy var descriptionLabel: UILabel = .build { label in
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .body,
                                                                   size: UX.descriptionFontSize)
        label.adjustsFontForContentSizeCategory = true
        label.accessibilityIdentifier = "\(self.viewModel.infoModel.a11yIdRoot)DescriptionLabel"
    }

    lazy var buttonStackView: UIStackView = .build { stack in
        stack.backgroundColor = .clear
        stack.distribution = .equalSpacing
        stack.spacing = UX.stackViewSpacing
        stack.axis = .vertical
    }

    private lazy var primaryButton: ResizableButton = .build { button in
        button.titleLabel?.font = DynamicFontHelper.defaultHelper.preferredBoldFont(
            withTextStyle: .callout,
            size: UX.buttonFontSize)
        button.layer.cornerRadius = UX.buttonCornerRadius
        button.titleLabel?.textAlignment = .center
        button.addTarget(self, action: #selector(self.primaryAction), for: .touchUpInside)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.accessibilityIdentifier = "\(self.viewModel.infoModel.a11yIdRoot)PrimaryButton"
        button.contentEdgeInsets = UIEdgeInsets(top: UX.buttonVerticalInset,
                                                left: UX.buttonHorizontalInset,
                                                bottom: UX.buttonVerticalInset,
                                                right: UX.buttonHorizontalInset)
    }

    private lazy var secondaryButton: ResizableButton = .build { button in
        button.titleLabel?.font = DynamicFontHelper.defaultHelper.preferredBoldFont(
            withTextStyle: .callout,
            size: UX.buttonFontSize)
        button.layer.cornerRadius = UX.buttonCornerRadius
        button.titleLabel?.textAlignment = .center
        button.addTarget(self, action: #selector(self.secondaryAction), for: .touchUpInside)
        button.accessibilityIdentifier = "\(self.viewModel.infoModel.a11yIdRoot)SecondaryButton"
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.contentEdgeInsets = UIEdgeInsets(top: UX.buttonVerticalInset,
                                                left: UX.buttonHorizontalInset,
                                                bottom: UX.buttonVerticalInset,
                                                right: UX.buttonHorizontalInset)
    }

    private lazy var linkButton: ResizableButton = .build { button in
        button.titleLabel?.font = DynamicFontHelper.defaultHelper.preferredFont(withTextStyle: .subheadline, size: UX.buttonFontSize)
        button.titleLabel?.textAlignment = .center
        button.addTarget(self, action: #selector(self.linkButtonAction), for: .touchUpInside)
        button.setTitleColor(.systemBlue, for: .normal)
        button.backgroundColor = .clear
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.contentEdgeInsets = UIEdgeInsets(top: UX.buttonVerticalInset,
                                                left: UX.buttonHorizontalInset,
                                                bottom: UX.buttonVerticalInset,
                                                right: UX.buttonHorizontalInset)
    }

    private var imageViewHeight: CGFloat {
        if shouldUseTinyDeviceLayout {
            return UX.tinyImageViewSize.height
        } else if shouldUseSmallDeviceLayout {
            return UX.imageViewSize.height
        } else {
            return UX.smallImageViewSize.height
        }
    }

    init(viewModel: OnboardingCardProtocol,
         delegate: OnboardingCardDelegate?,
         themeManager: ThemeManager = AppContainer.shared.resolve(),
         notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.viewModel = viewModel
        self.delegate = delegate
        self.themeManager = themeManager
        self.notificationCenter = notificationCenter

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        listenForThemeChange(view)
        setupView()
        updateLayout()
        applyTheme()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        delegate?.pageChanged(viewModel.cardType)
        viewModel.sendCardViewTelemetry()
    }

    func setupView() {
        view.backgroundColor = .clear

        topStackView.addArrangedSubview(imageView)
        topStackView.addArrangedSubview(titleLabel)
        topStackView.addArrangedSubview(descriptionBoldLabel)
        topStackView.addArrangedSubview(descriptionLabel)
        contentStackView.addArrangedSubview(topStackView)
        contentStackView.addArrangedSubview(linkButton)

        buttonStackView.addArrangedSubview(primaryButton)
        buttonStackView.addArrangedSubview(secondaryButton)
        contentStackView.addArrangedSubview(buttonStackView)

        contentContainerView.addSubview(contentStackView)
        containerView.addSubviews(contentContainerView)
        scrollView.addSubviews(containerView)
        view.addSubview(scrollView)

        // Adapt layout for smaller screens
        let scrollViewVerticalPadding = shouldUseSmallDeviceLayout ? UX.smallScrollViewVerticalPadding :  UX.scrollViewVerticalPadding
        let topPadding = UIDevice.current.userInterfaceIdiom == .pad ? UX.topStackViewPadding : (shouldUseSmallDeviceLayout ? UX.smallTopStackViewPadding : UX.topStackViewPadding)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: scrollViewVerticalPadding),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -scrollViewVerticalPadding),

            scrollView.frameLayoutGuide.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.frameLayoutGuide.topAnchor.constraint(equalTo: view.topAnchor, constant: scrollViewVerticalPadding),
            scrollView.frameLayoutGuide.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.frameLayoutGuide.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -scrollViewVerticalPadding),
            scrollView.frameLayoutGuide.heightAnchor.constraint(equalTo: containerView.heightAnchor).priority(.defaultLow),

            scrollView.contentLayoutGuide.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.contentLayoutGuide.topAnchor.constraint(equalTo: containerView.topAnchor),
            scrollView.contentLayoutGuide.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollView.contentLayoutGuide.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            // Content view wrapper around text
            contentContainerView.topAnchor.constraint(equalTo: containerView.topAnchor),
            contentContainerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            contentContainerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -UX.buttomStackViewPadding),
            contentContainerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

            contentStackView.topAnchor.constraint(greaterThanOrEqualTo: contentContainerView.topAnchor, constant: topPadding),
            contentStackView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            contentStackView.bottomAnchor.constraint(greaterThanOrEqualTo: contentContainerView.bottomAnchor, constant: -UX.buttomStackViewPadding).priority(.defaultLow),
            contentStackView.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor, constant: UX.stackViewPadding),
            contentStackView.centerYAnchor.constraint(equalTo: contentContainerView.centerYAnchor),

            topStackView.leadingAnchor.constraint(equalTo: contentStackView.leadingAnchor, constant: UX.horizontalTopStackViewPadding),
            topStackView.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor, constant: -UX.horizontalTopStackViewPadding),

            buttonStackView.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor, constant: UX.horizontalTopStackViewPadding),
            buttonStackView.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor),
            buttonStackView.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor, constant: -UX.horizontalTopStackViewPadding),

            imageView.heightAnchor.constraint(equalToConstant: imageViewHeight)
        ])

        topStackView.spacing = shouldUseSmallDeviceLayout ? UX.smallStackViewSpacing : UX.stackViewSpacing
        buttonStackView.spacing = shouldUseSmallDeviceLayout ? UX.smallStackViewSpacing : UX.stackViewSpacingButtons
    }

    private func updateLayout() {
        titleLabel.text = viewModel.infoModel.title
        descriptionBoldLabel.isHidden = !viewModel.shouldShowDescriptionBold
        descriptionBoldLabel.text = .Onboarding.Intro.DescriptionPart1
        descriptionLabel.isHidden = viewModel.infoModel.description?.isEmpty ?? true
        descriptionLabel.text = viewModel.infoModel.description

        imageView.image = viewModel.infoModel.image
        primaryButton.setTitle(viewModel.infoModel.primaryAction, for: .normal)
        handleSecondaryButton()
    }

    private func handleSecondaryButton() {
        // To keep Title, Description aligned between cards we don't hide the button
        // we clear the background and make disabled
        guard let buttonTitle = viewModel.infoModel.secondaryAction else {
            secondaryButton.isUserInteractionEnabled = false
            secondaryButton.backgroundColor = .clear
            return
        }

        secondaryButton.setTitle(buttonTitle, for: .normal)
    }

    private func handleLinkButton() {
        guard let buttonTitle = viewModel.infoModel.linkButtonTitle else {
            linkButton.isUserInteractionEnabled = false
            linkButton.isHidden = true
            return
        }
        linkButton.setTitle(buttonTitle, for: .normal)
    }

    @objc
    func primaryAction() {
        viewModel.sendTelemetryButton(isPrimaryAction: true)
        delegate?.primaryAction(viewModel.cardType)
    }

    @objc
    func secondaryAction() {
        viewModel.sendTelemetryButton(isPrimaryAction: false)
        delegate?.showNextPage(viewModel.cardType)
    }

    @objc
    func linkButtonAction() {
        // TODO: https://mozilla-hub.atlassian.net/browse/FXIOS-5850
    }

    // MARK: - Themeable
    func applyTheme() {
        let theme = themeManager.currentTheme
        titleLabel.textColor = theme.colors.textPrimary
        descriptionLabel.textColor  = theme.colors.textPrimary
        descriptionBoldLabel.textColor = theme.colors.textPrimary

        primaryButton.setTitleColor(theme.colors.textInverted, for: .normal)
        primaryButton.backgroundColor = theme.colors.actionPrimary

        secondaryButton.setTitleColor(theme.colors.textSecondaryAction, for: .normal)
        secondaryButton.backgroundColor = theme.colors.actionSecondary
        handleSecondaryButton()
        handleLinkButton()
    }
}
