;;;; color.lisp

(in-package #:sketch)

;;;   ____ ___  _     ___  ____
;;;  / ___/ _ \| |   / _ \|  _ \
;;; | |  | | | | |  | | | | |_) |
;;; | |__| |_| | |__| |_| |  _ <
;;;  \____\___/|_____\___/|_| \_\

;;; General

(defstruct color
  (red 0.0)
  (green 0.0)
  (blue 0.0)
  (hue 0.0)
  (saturation 0.0)
  (brightness 0.0)
  (alpha 1.0))

(defun rgb-to-hsb (r g b)
  (let* ((c-max (max r g b))
	 (c-min (min r g b))
	 (delta (- c-max c-min))
	 (hue (* 60 (cond ((= delta 0) 0)
			  ((= c-max r) (mod (/ (- g b) delta) 6))
			  ((= c-max g) (+ (/ (- b r) delta) 2))
			  ((= c-max b) (+ (/ (- r g) delta) 4)))))
	 (saturation (if (zerop c-max)
			 0
			 (/ delta c-max)))
	 (brightness c-max))
    (list (/ hue 360) saturation brightness)))

(defun hsb-to-rgb (h s b)
  (let* ((h (mod (* h 360) 360))
	 (c (* b s))
	 (x (* c (- 1 (abs (- (mod (/ h 60) 2) 1)))))
	 (m (- b c)))
    (mapcar (lambda (x) (+ m x))
	    (aref `#((,c ,x 0) (,x ,c 0) (0 ,c ,x)
		     (0 ,x ,c) (,x 0 ,c) (,c 0 ,x))
		  (floor (/ h 60))))))

(defun rgb (red green blue &optional (alpha 1.0))
  (destructuring-bind (red green blue alpha)
      (mapcar #'clamp-1 (list red green blue alpha))
    (let ((hsb (rgb-to-hsb red green blue)))
      (make-color :red red :green green :blue blue :alpha alpha
		  :hue (elt hsb 0) :saturation (elt hsb 1) :brightness (elt hsb 2)))))

(defun hsb (hue saturation brightness &optional (alpha 1.0))
  (destructuring-bind (hue saturation brightness alpha)
      (mapcar #'clamp-1 (list hue saturation brightness alpha))
    (let ((rgb (hsb-to-rgb hue saturation brightness)))
      (make-color :hue hue :saturation saturation :brightness brightness :alpha alpha
		  :red (elt rgb 0) :green (elt rgb 1) :blue (elt rgb 2)))))

(defun gray (amount &optional (alpha 1.0))
  (rgb amount amount amount alpha))

(defun rgb-255 (red green blue &optional (alpha 255))
  (rgb (/ red 255) (/ green 255) (/ blue 255) (/ alpha 255)))

(defun hsb-360 (hue saturation brightness &optional (alpha 255))
  (hsb (/ hue 360) (/ saturation 100) (/ brightness 100) (/ alpha 255)))

(defun gray-255 (amount &optional (alpha 255))
  (gray (/ amount 255) (/ alpha 255)))

(defun hex-to-color (string)
  (let ((string (string-left-trim "#" string)))
    (destructuring-bind (r g b &optional (a 1.0))
	(let* ((bits (case (length string)
		       ((3 4) 4)
		       ((6 8) 8)
		       (t (error "~a is not a valid hex color." string))))
	       (groups (group-bits (parse-integer string :radix 16 :junk-allowed t)
				   bits)))
	  (pad-list (mapcar (lambda (x) (/ x (if (= bits 4) 15 255))) groups)
		    0
		    (if (= 4 bits)
			(length string)
			(/ (length string) 2))))
      (rgb r g b a))))

(defun color-rgb (color)
  (list (color-red color)
	(color-green color)
	(color-blue color)))

(defun color-rgba (color)
  (list (color-red color)
	(color-green color)
	(color-blue color)
	(color-alpha color)))

(defun color-hsba (color)
  (list (color-hue color)
	(color-saturation color)
	(color-brightness color)
	(color-alpha color)))

(defun color-vector (color)
  (vector (coerce (color-red color) 'single-float)
	  (coerce (color-green color) 'single-float)
	  (coerce (color-blue color) 'single-float)
	  (coerce (color-alpha color) 'single-float)))

(defun color-vector-255 (color)
  (vector (coerce (truncate (* 255 (color-red color))) 'unsigned-byte)
	  (coerce (truncate (* 255 (color-green color))) 'unsigned-byte)
	  (coerce (truncate (* 255 (color-blue color))) 'unsigned-byte)
	  (coerce (truncate (* 255 (color-alpha color))) 'unsigned-byte)))

;;; Generators

(defun lerp-color (start-color end-color amount &key (mode :hsb))
  (let ((a (clamp-1 amount)))
    (flet ((norm (field)
	     (normalize a 0.0 1.0
			:out-low (slot-value start-color field)
			:out-high (slot-value end-color field))))
      (if (eq mode :hsb)
	  (apply #'hsb (mapcar #'norm '(hue saturation brightness alpha)))
	  (apply #'rgb (mapcar #'norm '(red green blue alpha)))))))

(defun random-color (&optional (alpha 1.0))
  (rgb (random 1.0) (random 1.0) (random 1.0) alpha))

(defun hash-color (n &optional (alpha 1.0))
  (let* ((grp (group-bits n))
	 (arr (make-array (length grp)
			  :element-type '(unsigned-byte 8)
			  :initial-contents grp))
	 (seq (md5:md5sum-sequence arr))
	 (hash (loop for i across seq sum i)))
    (hsb-360 (mod hash 359)
	     (alexandria:clamp (expt (mod (* n hash) 13) 3) 50 100)
	     (alexandria:clamp (expt (mod (* n hash) 17) 3) 50 100)
	     (* 255 alpha))))

;;; Filters

(defun color-filter-grayscale (color &optional (mode :luminosity))
  (case mode
    ((:lightness 1) (gray (/ (+ (apply #'max (color-rgb color))
			       (apply #'min (color-rgb color))))
			 (color-alpha color)))
    ((:average 2) (gray (/ (apply #'+ (color-rgb color)) 3)
		       (color-alpha color)))
    (t (gray (+ (* 0.21 (color-red color))
		(* 0.72 (color-green color))
		(* 0.07 (color-blue color)))
	     (color-alpha color)))))

(defun color-filter-invert (color)
  (hsb (let ((h (- (color-hue color) 0.5)))
	 (if (plusp h)
	     h
	     (+ 1 h)))
       (color-saturation color)
       (color-brightness color)
       (color-alpha color)))

(defun color-filter-rotate (color)
  (rgb (color-green color)
       (color-blue color)
       (color-red color)))

;;; Predefined colors

(defparameter +red+ (rgb 1 0 0))
(defparameter +green+ (rgb 0 1 0))
(defparameter +blue+ (rgb 0 0 1))
(defparameter +yellow+ (rgb 1 1 0))
(defparameter +magenta+ (rgb 1 0 1))
(defparameter +cyan+ (rgb 0 1 1))
(defparameter +white+ (gray 1))
(defparameter +black+ (gray 0))
