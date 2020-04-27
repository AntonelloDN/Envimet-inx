module Envimet
  module EnvimetInx
    module MessageBox
	  
	  def self.show_messagebox(title, message)
	    path = "res/icon/inx.png"
		
	    properties = { dialog_title:title, scrollable:false, width:650, height:150, style:UI::HtmlDialog::STYLE_DIALOG }
	    html = <<-HTML
		<html>
		<style>
		  body {
		    font-family: Arial, Helvetica, sans-serif;
			
		  }
		  table {
		    width:100%;
		  }
		  table, th, td {
		    border: 2px solid #1C2833;
			border-collapse: collapse;
		  }
		  th, td {
		    padding: 10px;
			text-align: center;
			font-size: 14px;
			background-color: #17202A;
			color: #D5D8DC;
		  }
		</style>
		  <body>
			<table>#{message}</table>
		  </body>
		</html>
		HTML
		
		dialog = UI::HtmlDialog.new(properties)
		dialog.set_html(html)
		dialog.center
		dialog.show_modal
	  end
	
	end # end MessageBox
  end # end EnvimetInx
end # end Envimet