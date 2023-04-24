function search_old(){
    var query = $('#query').val()
    window.location.href = '/old/search?query=' + query
}
window.search_old = search_old