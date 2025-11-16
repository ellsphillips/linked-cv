#import "src/colours.typ": colours, set-accent-colour
#import "src/typography.typ"
#import "src/utils.typ": *
#import "src/components.typ"
#import "src/layout.typ": layout
#import "src/frame.typ"

#let linked-cv(
  firstname: "First",
  lastname: "Last",
  socials: (
    email: none,
    mobile: none,
    github: none,
    linkedin: none,
  ),
  accent-colour: colours.accent,

  body,
) = {
  set-accent-colour(accent-colour)

  show: doc => layout(firstname, lastname, doc)

  components.header(
    firstname,
    lastname,
    socials: socials,
  )

  body
}
