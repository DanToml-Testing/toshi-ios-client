import Foundation
import UIKit
import Teapot

typealias PaymentInfo = (fiatString: String, estimatedFeesFiatString: String, estimatedFeesEtherString: String, totalFiatString: String, totalEthereumString: String, balanceString: String, sufficientBalance: Bool)
typealias RawPaymentInfo = (payedValue: NSDecimalNumber, estimatedFees: NSDecimalNumber, totalValue: NSDecimalNumber, balanceString: String, sufficientBalance: Bool)

enum PaymentParameters {
    static let from = "from"
    static let to = "to"
    static let value = "value"
    static let data = "data"
    static let gas = "gas"
    static let gasPrice = "gasPrice"
    static let nonce = "nonce"
    static let tokenAddress = "token_address"
    static let maxValue = "max"
}

class PaymentManager {

    private(set) var transaction: String?
    private var ethereumApiClient = EthereumAPIClient.shared
    private var exchangeRate = ExchangeRateClient.exchangeRate

    private var value: NSDecimalNumber {
        guard let valueString = parameters[PaymentParameters.value] as? String else { return .zero }

        return NSDecimalNumber(hexadecimalString: valueString)
    }

    var parameters: [String: Any]

    convenience init(parameters: [String: Any], mockTeapot: MockTeapot, exchangeRate: Decimal) {
        self.init(parameters: parameters)
        self.exchangeRate = exchangeRate
        self.ethereumApiClient = EthereumAPIClient(mockTeapot: mockTeapot)
    }

    init(parameters: [String: Any]) {
        self.parameters = parameters
    }

    func fetchRawPaymentInfo(completion: @escaping ((_ paymentInfo: RawPaymentInfo) -> Void)) {
        ethereumApiClient.transactionSkeleton(for: parameters) { [weak self] skeleton, error in
            guard let weakSelf = self else { return }

            if let error = error {
                Navigator.presentDismissableAlert(title: Localized.confirmation_error_transaction, message: error.description)
                return
            }

            guard let gasPrice = skeleton.gasPrice, let gas = skeleton.gas, let transaction = skeleton.transaction else { return }

            weakSelf.transaction = transaction

            let gasPriceValue = NSDecimalNumber(hexadecimalString: gasPrice)
            let gasValue = NSDecimalNumber(hexadecimalString: gas)

            let fee = gasPriceValue.decimalValue * gasValue.decimalValue
            let decimalNumberFee = NSDecimalNumber(decimal: fee)

            var value: NSDecimalNumber = .zero
            if let maxValueParam = weakSelf.parameters[PaymentParameters.value] as? String, maxValueParam == PaymentParameters.maxValue, let calculatedValue = skeleton.value {
                value = NSDecimalNumber(hexadecimalString: calculatedValue)
            } else {
                if weakSelf.parameters[PaymentParameters.tokenAddress] == nil {
                    value = weakSelf.value
                }
            }

            let totalWei = value.adding(decimalNumberFee)

            /// We don't care about the cached balance since we immediately want to know if the current balance is sufficient or not.
            weakSelf.ethereumApiClient.getBalance(cachedBalanceCompletion: { _, _ in }, fetchedBalanceCompletion: { fetchedBalance, error in
                if let error = error {
                    Navigator.presentDismissableAlert(title: Localized.confirmation_error_balance, message: error.description)
                    return
                }

                let balanceString = EthereumConverter.fiatValueStringWithCode(forWei: fetchedBalance, exchangeRate: weakSelf.exchangeRate)
                let sufficientBalance = fetchedBalance.isGreaterOrEqualThan(value: totalWei)

                let rawPaymentInfo = RawPaymentInfo(payedValue: value, estimatedFees: decimalNumberFee, totalValue: totalWei, balanceString: balanceString, sufficientBalance: sufficientBalance)
                completion(rawPaymentInfo)
            })
        }
    }

    func fetchPaymentInfo(completion: @escaping ((_ paymentInfo: PaymentInfo) -> Void)) {

        fetchRawPaymentInfo { [weak self] rawPaymentInfo in
            guard let weakSelf = self else { return }

            let fiatString = EthereumConverter.fiatValueStringWithCode(forWei: weakSelf.value, exchangeRate: weakSelf.exchangeRate)
            let estimatedFeesFiatString = EthereumConverter.fiatValueStringWithCode(forWei: rawPaymentInfo.estimatedFees, exchangeRate: weakSelf.exchangeRate)
            let estimatedFeesEtherString = EthereumConverter.ethereumValueString(forWei: rawPaymentInfo.estimatedFees)

            let totalFiatString = EthereumConverter.fiatValueStringWithCode(forWei: rawPaymentInfo.totalValue, exchangeRate: weakSelf.exchangeRate)
            let totalEthereumString = EthereumConverter.ethereumValueString(forWei: rawPaymentInfo.totalValue)

            let paymentInfo = PaymentInfo(fiatString: fiatString, estimatedFeesFiatString: estimatedFeesFiatString, estimatedFeesEtherString: estimatedFeesEtherString, totalFiatString: totalFiatString, totalEthereumString: totalEthereumString, balanceString: rawPaymentInfo.balanceString, sufficientBalance: rawPaymentInfo.sufficientBalance)
            completion(paymentInfo)
        }
    }

    func sendPayment(completion: @escaping ((_ error: ToshiError?, _ transactionHash: String?) -> Void)) {
        guard let transaction = transaction else { return }
        let signedTransaction = "0x\(Cereal.shared.signWithWallet(hex: transaction))"

        ethereumApiClient.sendSignedTransaction(originalTransaction: transaction, transactionSignature: signedTransaction) { _, transactionHash, error in
            if let error = error {
                Navigator.presentDismissableAlert(title: Localized.confirmation_error_payment, message: error.description)
                return
            }
            
            completion(error, transactionHash)
        }
    }
}
