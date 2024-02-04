# Concept

## Introduction

dos-8, picos, and other carts within this repo represent my neocities website overhaul, or at least my attempt at making an interesting one.

## User experience

The user experience is a bit different than a typical website. Keeping with the asthetic of the 90s, the user is presented with a jpg of a cluttered desk with a series of items on it. Each item is a link to a different page. The user can click on the items to navigate to different pages. The user can also click on the computer to navigate to the main page, which is a DOS prompt powered by DOS-8 (a custom cart in pico-8). 

The idea is to make the user feel like they are navigating a computer from the 90s, specifically a DOS computer with the ability to grab a diskette and run / install a program. 

## Technical

The website is powered by neocities, which is a free hosting service for static websites. The website is built using HTML, CSS, and JavaScript. The website is also powered by pico-8 carts, which are small games / programs that can be embedded into a website.

The pico 8 cart html and js exported by the program has access to GPIO pins, which can be used to communicate with the cart. This is how the website is able to communicate with the carts. It only has access to 128 bytes of memory, so the communication will be limited to simple commands and responses.

## Design

The design should be as basic as possible, keeping with the 90s geocities asthetic. The website could be a set of jpgs someone stacked on top of each other, with links to different pages. The website should be simple and easy to navigate, with a focus on the user experience. This way it could mimic items on the desk.

## "Gameplay" loop

1. User navigates to the website
2. User is presented with a cluttered desk
3. User clicks on an item to navigate to a different page
4. User can click on the computer to navigate to DOS-8
  - User must find out how to log in as guest, which presents clues on how to login as the main account, which gives the ability to install programs.
  - The user can find a diskette called "picos" which is a link to the picos cart. Once they click on this link, it becomes available in the cart page as a disk they can insert.
  - Once the disk is inserted and the install program ran, the user can navigate to the picos directory and run the program
5. The picOS cart is loaded, and is a simple GUI-based operating system that the user can interact with. The user can navigate a set of very basic programs, such as a text editor, a calculator, and a file manager. The user can also open a web browser, which navigates to the main page of the website. (within the website there is a guest book, which the user can sign and leave a message. The user can also see other messages. This is enabled by GPIO integration)
6. The user can navigate the website much like a normal website, and is a highly simplified geocities-like website.
7. The user can recursively find the picos monitor on a desk image, and when clicking it loads a new cart
  - This new cart is a shift in perspective, and shows the user represented as a character in a game falling into the website. The user can navigate the website as a game, and can user the webring to navigate to other websites, finding characters that represent other users. The user can also find a way to navigate back to the main website, and can find a way to navigate back to the DOS-8 prompt.
8. The user can navigate back to the DOS-8 prompt, and can find a way to navigate to the main website. The user can also find a way to navigate to the picos cart, and can find a way to navigate to the game cart.
  - If the user can find a way to navigate all the way back to the beginning cluttered desk, they can find a way to navigate to a secret page that shows the user a message and a link to a secret page on the website with a special guest book.

