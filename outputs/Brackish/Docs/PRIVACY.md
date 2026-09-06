# Privacy

Brackish does not collect user data on a developer-operated server. There is no
account, custom backend, analytics, advertising, tracking, subscription or required
service credential. The app contains no network-based photo recognition path.

A photograph selected in the system Photos picker or taken in the camera is
processed on-device. Only selected photos are accessed. A decoded/re-encoded JPEG
is stored; original EXIF/GPS metadata and filenames are discarded. The displayed
pixels can still reveal a place or person. The included tests verify GPS removal
and orientation preservation.

Location permission is requested only after Near me. The app requests kilometer
accuracy, keeps the result in memory, and uses it for straight-line distances.
A catch's area is manually chosen from broad borough names or withheld. Coordinates
are not recorded in catch entries. Explore by borough without granting permission.

Private JSON, JPEG and unfinished-photo files are in the app's Application Support
directory, protected with complete iOS file protection, excluded from cloud backup,
and inaccessible through iTunes file sharing. Brackish does not sync. iOS device
security and possession of an unlocked device remain relevant. Export before
changing devices or deleting the app if you want to retain the journal.

Export uses the iOS file exporter. Photos, dates, measurements, checklists and saved
spots are included. Notes and catch area are omitted unless explicitly enabled.
Exported files can contain sensitive written/visible details. Brackish cannot
recall or delete copies exported to Files or shared with another application.
Delete-entry removes that entry/photo. Delete-all removes the local journal,
photos, drafts, bookmarks and checklists and returns to onboarding.

MapKit may contact Apple to fetch map imagery. External directions, tackle searches
and source links leave Brackish and are governed by the destination's privacy
policy. There is no claim that Apple Maps or those websites are offline or anonymous.
Reference descriptions and species notes are bundled; external map tiles/resources
can be unavailable while the journal, comparison and checklists still work.

Privacy manifest: no tracking and no collected data declarations. Apple frameworks
remain platform dependencies. Before store submission, review the final binary
and Apple's current required-reason API guidance; this project has not been
submitted to App Store Connect or represented as having completed an App Store review.
