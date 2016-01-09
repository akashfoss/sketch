;;;; sketch.asd

(asdf:defsystem #:sketch
  :description "Sketch"
  :author "Danilo Vidovic (vydd)"
  :license "MIT"
  :depends-on (#:alexandria
	       #:cl-geometry
	       #:glkit
	       #:mathkit
	       #:md5
	       #:sb-cga
	       #:sdl2-image
	       #:sdl2kit
	       #:static-vectors)
  :pathname "src"
  :serial t
  :components ((:file "package")
	       (:file "math")
	       (:file "utils" :depends-on ("package" "math"))
	       (:file "channels" :depends-on ("package" "utils"))
	       (:file "shaders" :depends-on ("package"))
	       (:file "environment" :depends-on ("package" "shaders"))
	       (:file "color" :depends-on ("package" "utils"))
	       (:file "pen" :depends-on ("package" "color" "environment"))
	       (:file "geometry" :depends-on ("package"))
	       (:file "drawing" :depends-on ("package" "geometry"))
	       (:file "shapes" :depends-on ("package" "drawing"))
	       (:file "transforms" :depends-on ("package" "environment"))
	       (:file "images")
	       (:file "figures")
               (:file "sketch")
	       (:file "controllers")))
