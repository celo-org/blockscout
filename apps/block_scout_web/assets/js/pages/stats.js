import $ from 'jquery'

$(window).on('load resize', function () {
  const width = $(window).width()
  if (width < 768) {
    $('.pt').removeClass('pt-5')
    $('.menu-wrap').removeClass('container')
  } else {
    $('.pt').addClass('pt-5')
    $('.menu-wrap').addClass('container')
  }
})
