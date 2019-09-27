// Linc snippet
window.lincOptinAsyncInit = function() {
   LincOptin.init({
     publicId: 'c88fb064-c0d0-11e6-ae83-0644c1b5a0d1',
     language: 'en_US'
   });
};

(function(d, s, id) {
 var js, ljs = d.getElementsByTagName(s)[0];
 if (d.getElementById(id)) { return; }
 js = d.createElement(s); js.id = id;
 js.src = '//connect.letslinc.com/v1/optinWidget.js';
 ljs.parentNode.insertBefore(js, ljs);
} (document, 'script', 'linc-optin-js'));
// // <!-- End Linc opt-in widget code snippet -->

// Facebook Javascript SDK
(function(d, s, id){
   var js, fjs = d.getElementsByTagName(s)[0];
   if (d.getElementById(id)) { return; }
   js = d.createElement(s); js.id = id;
   js.src = "//connect.facebook.net/en_US/sdk.js";
   fjs.parentNode.insertBefore(js, fjs);
}(document, 'script', 'facebook-jssdk'));
// End of Facebook Javascript SDK

// <!-- Bing Ads Conversion Tracking -->
(function(w,d,t,r,u){var f,n,i;w[u]=w[u]||[],f=function(){var o={ti:"5820699"};o.q=w[u],w[u]=new UET(o),w[u].push("pageLoad")},n=d.createElement(t),n.src=r,n.async=1,n.onload=n.onreadystatechange=function(){var s=this.readyState;s&&s!=="loaded"&&s!=="complete"||(f(),n.onload=n.onreadystatechange=null)},i=d.getElementsByTagName(t)[0],i.parentNode.insertBefore(n,i)})(window,document,"script","//bat.bing.com/bat.js","uetq");

// <!-- Start VWO Asynchronous Code -->
  var _vwo_code=(function(){
  var account_id=356357,
  settings_tolerance=2000,
  library_tolerance=2500,
  use_existing_jquery=false,
  f=false,d=document;return{use_existing_jquery:function(){return use_existing_jquery;},library_tolerance:function(){return library_tolerance;},finish:function(){if(!f){f=true;var a=d.getElementById('_vis_opt_path_hides');if(a)a.parentNode.removeChild(a);}},finished:function(){return f;},load:function(a){var b=d.createElement('script');b.src=a;b.type='text/javascript';b.innerText;b.onerror=function(){_vwo_code.finish();};d.getElementsByTagName('head')[0].appendChild(b);},init:function(){settings_timer=setTimeout('_vwo_code.finish()',settings_tolerance);var a=d.createElement('style'),b='body{opacity:0 !important;filter:alpha(opacity=0) !important;background:none !important;}',h=d.getElementsByTagName('head')[0];a.setAttribute('id','_vis_opt_path_hides');a.setAttribute('type','text/css');if(a.styleSheet)a.styleSheet.cssText=b;else a.appendChild(d.createTextNode(b));h.appendChild(a);this.load('//dev.visualwebsiteoptimizer.com/j.php?a='+account_id+'&u='+encodeURIComponent(d.URL)+'&r='+Math.random());return settings_timer;}};}());_vwo_settings_timer=_vwo_code.init();
// <!-- End VWO Asynchronous Code -->
