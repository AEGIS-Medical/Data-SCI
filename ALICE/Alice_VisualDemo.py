# In[ ]:
#pip install opencv-python

import cv2
import numpy as py



# In[ ]:


face_dectection = cv2.CascadeClassier(haarcascade_frontalface_default.xml)
smile_dectector = cv2.CascadeClassier(haarcascade_smile.xml)
#profiler = cv2.CascadeClassier(haarcascade_profileface.xml)
eye_movement = cv2.CascadeClassier(haarcascade_eye.xml)


# In[ ]:


#activation of webcam footage
webcam = cv2.VideoCapture(0) #can be mp4 file


# In[ ]:


#cap current frame
while True:
    successful_frame_read, frame = webcam.read()
    #error handle
    if not successful_frame_read:
        break
    #grayscale for processing quicker
    frame_grayscale = sv2.cvrColor(frame, cv2.COLOR_BGR2GRAY)
    
    faces = face_detector.detectMultiScale(frame_grayscale, scalefactor = 1.3, minNeighbors = 5)
  
    
    for (x, y, w, h) in faces:
        #Draws rectange around colored frame
        cv2.rectangle(frame, (x,y), (x+w, y+h), (100, 200, 50), 4)
        
        the_face = frame[y:y+h, z:z+w]
        
        face_grayscale = v2.cvrColor(the_face, cv2.COLOR_BGR2GRAY)
        
        smiles = smile_detector.detectMultiScale(face_grayscale, scalefactor = 1.7, minNeighbors = 20) 
        #profile = profiler.detectMultiScale(face_grayscale)
        eyes = eye_movement.detectMultiScale(face_grayscale, 1.1, 10)
        
        for (x_,y_,w_,h_) in smiles:
            
            cv2.rectangle(the_face, (x_,y_), (x_+w_, y_+h_), (50, 50, 200), 4)
  
        if len(smiles) > 0:
            cv2.putText(frame, "Possibly Lying", (x, y+h+40), fontScale = 3, fontFace = cv2.FONT_HERSHESY, color = (255, 255, 255))
    
   # for x, y, w, h in profile:
        #Draws rectange around colored frame
   #     cv2.rectangle(frame, (x,y), (x+w, y+h), (100, 100, 100), 4)
    
        for (x_, y_, w_, h_) in eyes:
        #Draws rectange around colored frame
            cv2.rectangle(the_face, (x,y), (x+w, y+h), (100, 50, 200), 4)
        
        #face = frame
    
    #print(faces) this is location information for the face
    
    cv2.imshow("Is smile", frame_grayscale)
    #Display
    cv2.waitKey(8) #wait until userhits a key, first frame only or 10 millisec pass
#Eliminating the recording
webcam.release()
cv2.destroyAllWindows()


# In[ ]:
