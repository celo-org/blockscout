import $ from 'jquery'

$('.stats-link').on('click', function () {
  $('ul#topnav .selected').removeClass('selected')
  $(this).addClass('selected')
})

$(window).on('load resize', function () {
  var width = $(window).width()
  if (width < 768) {
    $('.js-ad-dependant-pt').removeClass('pt-5')
    $('.menu-wrap').removeClass('container')
    if (localStorage.getItem('current-color-mode') === 'dark') {
      $('.menu-wrap').addClass('dark')
    } else {
      $('.menu-wrap').removeClass('dark')
    }
  } else {
    $('.js-ad-dependant-pt').addClass('pt-5')
    $('.menu-wrap').addClass('container')
  }
})
