require 'rails_helper'

describe 'Editing page' do
  before { login_as create :admin }

  it 'grants permission to edit a page', js: true do
    @page = create :page, :with_image

    visit edit_page_path(@page)

    expect(page).to have_title 'Edit Page test title - Base'
    expect(page).to have_active_navigation_items 'Page test navigation title'
    expect(page).to have_breadcrumbs 'Base', 'Page test navigation title', 'Edit'
    expect(page).to have_headline 'Edit Page test title'

    fill_in 'page_title',            with: 'A new title'
    fill_in 'page_navigation_title', with: 'A new navigation title'
    fill_in 'page_content',          with: "A new content with a ![existing image](some-existing-identifier) and a ![new image](some-new-identifier)"
    fill_in 'page_notes',            with: 'A new note'

    find('#page_images_attributes_0_file', visible: false).set base64_other_image[:data]
    fill_in 'page_images_attributes_0_identifier', with: 'some-existing-identifier'

    expect {
      click_link 'Add image'
    } .to change { all('#images .nested-fields').count }.by 1

    scroll_by(0, 10000) # Otherwise the footer overlaps the element and results in a Capybara::Poltergeist::MouseEventFailed, see http://stackoverflow.com/questions/4424790/cucumber-capybara-scroll-to-bottom-of-page
    identifier_input_id = all('#images .nested-fields input[id$="identifier"]').last[:id]
    fill_in identifier_input_id, with: 'some-new-identifier'
    file_input_id = all('#images .nested-fields textarea[id$="file"]').last[:id]
    fill_in file_input_id, with: base64_image[:data]

    within '.actions' do
      expect(page).to have_css 'h2', text: 'Actions'

      expect(page).to have_button 'Update Page'
      expect(page).to have_link 'List of Pages'
    end

    expect {
      click_button 'Update Page'
      @page.reload
    } .to  change { @page.title }.to('A new title')
      .and change { @page.navigation_title }.to('A new navigation title')
      .and change { @page.content }.to("A new content with a ![existing image](some-existing-identifier) and a ![new image](some-new-identifier)")
      .and change { @page.notes }.to('A new note')
      .and change { @page.images.count }.by(1)
      .and change { @page.images.first.file.file.identifier }.to('file.png')
      .and change { @page.images.first.identifier }.to('some-existing-identifier')
      .and change { @page.images.last.file.file.identifier }.to('file.png')
      .and change { @page.images.last.identifier }.to('some-new-identifier')
  end

  it "prevents from overwriting other users' changes accidently (caused by race conditions)" do
    @page = create :page
    visit edit_page_path(@page)

    # Change something in the database...
    expect {
      @page.update_attributes content: 'This is the old content'
    }.to change { @page.lock_version }.by 1

    fill_in 'page_content', with: 'This is the new content, yeah!'

    expect {
      click_button 'Update Page'
      @page.reload
    }.not_to change { @page }

    expect(page).to have_flash('Alert: Page meanwhile has been changed. The conflicting field is: Content.').of_type :alert

    expect {
      click_button 'Update Page'
      @page.reload
    } .to change { @page.content }.to('This is the new content, yeah!')
  end
end