import $ from 'jquery'
import omit from 'lodash/omit'
import URI from 'urijs'
import humps from 'humps'
import { subscribeChannel } from '../socket'
import { createStore, connectElements } from '../lib/redux_helpers.js'
import '../app'
import Dropzone from 'dropzone'

export const initialState = {
  channelDisconnected: false,
  addressHash: null,
  validationErrors: null,
  newForm: null
}

export function reducer (state = initialState, action) {
  switch (action.type) {
    case 'PAGE_LOAD':
    case 'ELEMENTS_LOAD': {
      return Object.assign({}, state, omit(action, 'type'))
    }
    case 'CHANNEL_DISCONNECTED': {
      if (state.beyondPageOne) return state

      return Object.assign({}, state, {
        channelDisconnected: true
      })
    }
    case 'RECEIVED_VERIFICATION_RESULT': {
      if (action.msg.verificationResult === 'ok') {
        return window.location.replace(window.location.href.split('/contract-verifications')[0].split('/verify')[0] + '/contracts')
      } else {
        try {
          const result = JSON.parse(action.msg.verificationResult)

          return Object.assign({}, state, {
            validationErrors: result.errors
          })
        } catch {
          // TODO: get rid of it when other paths are updated as well
          return Object.assign({}, state, {
            newForm: action.msg.verificationResult
          })
        }
      }
    }
    default:
      return state
  }
}

function resetForm () {
  $(function () {
    $('.js-btn-add-contract-libraries').on('click', function () {
      $('.js-smart-contract-libraries-wrapper').show()
      $(this).hide()
    })

    $('.js-smart-contract-form-reset').on('click', function () {
      $('.js-contract-library-form-group').removeClass('active')
      $('.js-contract-library-form-group').first().addClass('active')
      $('.js-smart-contract-libraries-wrapper').hide()
      $('.js-btn-add-contract-libraries').show()
      $('.js-add-contract-library-wrapper').show()
    })

    $('.js-btn-add-contract-library').on('click', function () {
      const nextContractLibrary = $('.js-contract-library-form-group.active').next('.js-contract-library-form-group')

      if (nextContractLibrary) {
        nextContractLibrary.addClass('active')
      }

      if ($('.js-contract-library-form-group.active').length === $('.js-contract-library-form-group').length) {
        $('.js-add-contract-library-wrapper').hide()
      }
    })
  })
}

function clearValidationErrors () {
  $('.form-error').remove()
}

function renderValidationErrors (errors) {
  clearValidationErrors()

  errors.forEach((error) => {
    const { field, message } = error
    const fieldName = field.replaceAll('_', '-')

    $(`<span class="text-danger form-error" data-test="${fieldName}-error" id="${fieldName}-help-block">${message}</span>`).insertAfter(`[name="smart_contract[${field}]"]`)
  })
}

function updateFormState (locked) {
  if (locked) {
    document.getElementById('loading').classList.remove('d-none')
  } else {
    document.getElementById('loading').classList.add('d-none')
  }

  const controls = document.getElementsByClassName('form-control')
  controls.forEach((control) => { control.disabled = locked })
}

const elements = {
  '[data-selector="channel-disconnected-message"]': {
    render ($el, state) {
      if (state.channelDisconnected) $el.show()
    }
  },
  '[data-page="contract-verification"]': {
    render ($el, state) {
      if (state.validationErrors) {
        updateFormState(false)
        renderValidationErrors(state.validationErrors)
      } else if (state.newForm) {
        $el.replaceWith(state.newForm)
        resetForm()
      }

      return $el
    }
  }
}

const $contractVerificationPage = $('[data-page="contract-verification"]')
const $contractVerificationChooseTypePage = $('[data-page="contract-verification-choose-type"]')

function filterNightlyBuilds (filter) {
  const select = document.getElementById('smart_contract_compiler_version')
  const options = select.getElementsByTagName('option')
  for (const option of options) {
    const txtValue = option.textContent || option.innerText
    if (filter) {
      if (txtValue.toLowerCase().indexOf('nightly') > -1) {
        option.style.display = 'none'
      } else {
        option.style.display = ''
      }
    } else {
      if (txtValue.toLowerCase().indexOf('nightly') > -1) {
        option.style.display = ''
      }
    }
  }
}

if ($contractVerificationPage.length) {
  const store = createStore(reducer)
  const addressHash = $('#smart_contract_address_hash').val()
  const { filter, blockNumber } = humps.camelizeKeys(URI(window.location).query(true))
  const $form = $contractVerificationPage.find('form')

  $form.on('submit', (e) => {
    e.preventDefault() // avoid to execute the actual submit of the form.

    if ($form.get(0).checkValidity() === false) {
      return false
    }

    $.ajax({
      type: 'POST',
      url: $form.attr('action'),
      data: $form.serialize()
    })

    updateFormState(true)
  })

  store.dispatch({
    type: 'PAGE_LOAD',
    addressHash,
    filter,
    beyondPageOne: !!blockNumber
  })
  connectElements({ store, elements })

  const addressChannel = subscribeChannel(`addresses:${addressHash}`)

  addressChannel.onError(() => store.dispatch({
    type: 'CHANNEL_DISCONNECTED'
  }))
  addressChannel.on('verification', (msg) => store.dispatch({
    type: 'RECEIVED_VERIFICATION_RESULT',
    msg: humps.camelizeKeys(msg)
  }))

  $(function () {
    if ($('#metadata-json-dropzone').length) {
      var dropzone = new Dropzone('#metadata-json-dropzone', {
        autoProcessQueue: false,
        acceptedFiles: 'text/plain,application/json,.sol,.json',
        parallelUploads: 100,
        uploadMultiple: true,
        addRemoveLinks: true,
        maxFilesize: 20,
        params: { address_hash: $('#smart_contract_address_hash').val() },
        init: function () {
          this.on('addedfile', function (_file) {
            changeVisibilityOfVerifyButton(this.files.length)
            clearValidationErrors()
          })

          this.on('removedfile', function (_file) {
            changeVisibilityOfVerifyButton(this.files.length)
          })
        },
        success: function (file, response) {
          file.status = Dropzone.QUEUED
        },
        error: function (file, errorMessage, xhr) {
          file.status = Dropzone.QUEUED
        }
      })
    }

    function changeVisibilityOfVerifyButton (filesLength) {
      document.getElementById('verify-via-json-submit').disabled = (filesLength === 0)
    }

    setTimeout(function () {
      $('.nightly-builds-false').trigger('click')
    }, 10)

    $('.js-btn-add-contract-libraries').on('click', function () {
      $('.js-smart-contract-libraries-wrapper').show()
      $(this).hide()
    })

    $('.autodetectfalse').on('click', function () {
      if ($(this).prop('checked')) { $('.constructor-arguments').show() }
    })

    $('.autodetecttrue').on('click', function () {
      if ($(this).prop('checked')) { $('.constructor-arguments').hide() }
    })

    $('.nightly-builds-true').on('click', function () {
      if ($(this).prop('checked')) { filterNightlyBuilds(false) }
    })

    $('.nightly-builds-false').on('click', function () {
      if ($(this).prop('checked')) { filterNightlyBuilds(true) }
    })

    $('.optimization-false').on('click', function () {
      if ($(this).prop('checked')) { $('.optimization-runs').hide() }
    })

    $('.optimization-true').on('click', function () {
      if ($(this).prop('checked')) { $('.optimization-runs').show() }
    })

    $('.js-smart-contract-form-reset').on('click', function () {
      $('.js-contract-library-form-group').removeClass('active')
      $('.js-contract-library-form-group').first().addClass('active')
      $('.js-smart-contract-libraries-wrapper').hide()
      $('.js-btn-add-contract-libraries').show()
      $('.js-add-contract-library-wrapper').show()
    })

    $('.js-btn-add-contract-library').on('click', function () {
      const nextContractLibrary = $('.js-contract-library-form-group.active').next('.js-contract-library-form-group')

      if (nextContractLibrary) {
        nextContractLibrary.addClass('active')
      }

      if ($('.js-contract-library-form-group.active').length === $('.js-contract-library-form-group').length) {
        $('.js-add-contract-library-wrapper').hide()
      }
    })

    $('#verify-via-json-submit').on('click', function (e) {
      e.preventDefault()

      if (dropzone.files.length === 0) {
        return
      }

      updateFormState(true)
      dropzone.processQueue()
    })
  })
} else if ($contractVerificationChooseTypePage.length) {
  $('#smart_contract_address_hash').on('change load input ready', function () {
    const address = ($('#smart_contract_address_hash').val())

    const onContractUnverified = () => {
      document.getElementById('message-address-verified').hidden = true
      document.getElementById('message-link').removeAttribute('href')
      document.getElementById('data-button').disabled = false
    }

    const onContractVerified = (address) => {
      document.getElementById('message-address-verified').hidden = false
      document.getElementById('message-link').setAttribute('href', `/address/${address}/contracts`)
      document.getElementById('data-button').disabled = true
    }

    const isContractVerified = (result) => {
      return result &&
        result[0].ABI !== undefined &&
        result[0].ABI !== 'Contract source code not verified'
    }

    $.get(`/api/?module=contract&action=getsourcecode&address=${address}`).done(
      response => {
        if (isContractVerified(response.result)) {
          onContractVerified(address)
        } else {
          onContractUnverified()
        }
      }).fail(onContractUnverified)
  })

  $('.verify-via-flattened-code').on('click', function () {
    if ($(this).prop('checked')) {
      $('#verify_via_flattened_code_button').show()
      $('#verify_via_sourcify_button').hide()
      $('#verify_vyper_contract_button').hide()
    }
  })

  $('.verify-via-sourcify').on('click', function () {
    if ($(this).prop('checked')) {
      $('#verify_via_flattened_code_button').hide()
      $('#verify_via_sourcify_button').show()
      $('#verify_vyper_contract_button').hide()
    }
  })

  $('.verify-vyper-contract').on('click', function () {
    if ($(this).prop('checked')) {
      $('#verify_via_flattened_code_button').hide()
      $('#verify_via_sourcify_button').hide()
      $('#verify_vyper_contract_button').show()
    }
  })
}
