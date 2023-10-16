import $ from 'jquery'
import { openErrorModal, openWarningModal, openSuccessModal, openModalWithMessage } from '../modals'
import { compareChainIDs, formatError, formatTitleAndError, getContractABI, getCurrentAccountPromise, getMethodInputs, prepareMethodArgs } from './common_helpers'
import { fullPath } from '../utils'

export const queryMethod = (isWalletEnabled, url, $methodId, args, type, functionName, $responseContainer, isCustomABI) => {
  const data = {
    function_name: functionName,
    method_id: $methodId.val(),
    type,
    is_custom_abi: isCustomABI
  }

  data.args_count = args.length
  let i = args.length

  while (i--) {
    data['arg_' + i] = args[i]
  }

  if (isWalletEnabled) {
    getCurrentAccountPromise(window.web3 && window.web3.currentProvider)
      .then((currentAccount) => {
        data.from = currentAccount
        $.get(url, data, response => $responseContainer.html(response))
      }
      )
  } else {
    $.get(url, data, response => $responseContainer.html(response))
  }
}

export const callMethod = (isWalletEnabled, $functionInputs, explorerChainId, $form, functionName, $element) => {
  if (!isWalletEnabled) {
    const warningMsg = 'Wallet is not connected.'
    return openWarningModal('Unauthorized', warningMsg)
  }
  const contractAbi = getContractABI($form)
  const inputs = getMethodInputs(contractAbi, functionName)

  const $functionInputsExceptTxValue = $functionInputs.filter(':not([tx-value])')
  const args = prepareMethodArgs($functionInputsExceptTxValue, inputs)

  const txValue = getTxValue($functionInputs)
  const contractAddress = $form.data('contract-address')

  window.web3.eth.getChainId()
    .then((walletChainId) => {
      compareChainIDs(explorerChainId, walletChainId)
        .then(() => getCurrentAccountPromise(window.web3.currentProvider))
        .catch(error => {
          openWarningModal('Unauthorized', formatError(error))
        })
        .then((currentAccount) => {
          if (isSanctioned(currentAccount)) {
            openErrorModal('Error in sending transaction', sanctionText, false)
            return
          }

          if (functionName) {
            const TargetContract = new window.web3.eth.Contract(contractAbi, contractAddress)
            const sendParams = { from: currentAccount, value: txValue || 0 }
            const methodToCall = TargetContract.methods[functionName](...args).send(sendParams)
            methodToCall
              .on('error', function (error) {
                const titleAndError = formatTitleAndError(error)
                const txUrl = fullPath(`/tx/${titleAndError.txHash}`)
                const message = titleAndError.message + (titleAndError.txHash ? `<br><a href="${txUrl}">More info</a>` : '')
                openErrorModal(titleAndError.title.length ? titleAndError.title : `Error in sending transaction for method "${functionName}"`, message, false)
              })
              .on('transactionHash', function (txHash) {
                onTransactionHash(txHash, functionName)
              })
          } else {
            const txParams = {
              from: currentAccount,
              to: contractAddress,
              value: txValue || 0
            }
            window.ethereum.request({
              method: 'eth_sendTransaction',
              params: [txParams]
            })
              .then(function (txHash) {
                onTransactionHash(txHash, functionName)
              })
              .catch(function (error) {
                openErrorModal('Error in sending transaction for fallback method', formatError(error), false)
              })
          }
        })
        .catch(error => {
          openWarningModal('Unauthorized', formatError(error))
        })
    })
}

const sanctionString = document.getElementById("sanctions").getAttribute("data-sanctions")
const sanctionedAddresses =  JSON.parse(sanctionString).map(a => a.toLowerCase())
const sanctionText = 'The wallet address has been sanctioned by the U.S. Department of the Treasury. All U.S. persons are prohibited from accessing, receiving, accepting, or facilitating any property and interests in property (including use of any technology, software or software patch(es)) of these designated digital wallet addresses. These prohibitions include the making of any contribution or provision of funds, goods, or services by, to, or for the benefit of any blocked person and the receipt of any contribution or provision of funds, goods, or services from any such person and all designated digital asset wallets.'

function isSanctioned (address) {
  return address && sanctionedAddresses.includes(address.toLowerCase())
}

function onTransactionHash (txHash, functionName) {
  openModalWithMessage($('#pending-contract-write'), true, txHash)
  const getTxReceipt = (txHash) => {
    window.ethereum.request({
      method: 'eth_getTransactionReceipt',
      params: [txHash]
    })
      .then(txReceipt => {
        if (txReceipt) {
          const successMsg = `Successfully sent <a href="/tx/${txHash}">transaction</a> for method "${functionName}"`
          openSuccessModal('Success', successMsg)
          clearInterval(txReceiptPollingIntervalId)
        }
      })
  }
  const txReceiptPollingIntervalId = setInterval(() => { getTxReceipt(txHash) }, 5 * 1000)
}

function getTxValue ($functionInputs) {
  const WEI_MULTIPLIER = 10 ** 18
  const $txValue = $functionInputs.filter('[tx-value]:first')
  const txValue = $txValue && $txValue.val() && parseFloat($txValue.val()) * WEI_MULTIPLIER
  let txValueStr = txValue && txValue.toString(16)
  if (!txValueStr) {
    txValueStr = '0'
  }
  return '0x' + txValueStr
}
